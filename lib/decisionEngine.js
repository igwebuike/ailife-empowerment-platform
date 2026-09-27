import { query } from './db'

const allowedMetrics = new Set(['contribution_count','contribution_paid_count','contribution_missed_count','contribution_on_time_rate','bureau_score','prior_risk_score','loan_count'])
function compare(a,op,b){a=Number(a);b=Number(b);return ({eq:a===b,neq:a!==b,gt:a>b,gte:a>=b,lt:a<b,lte:a<=b})[op]||false}
export async function customerMetrics(customerId){
  const [contrib,bureau,risk,loans]=await Promise.all([
    query(`select count(*)::int total,count(*) filter(where lower(c.status)='paid')::int paid,count(*) filter(where lower(c.status) in ('overdue','missed'))::int missed from contributions c join organization_members m on m.id=c.member_id where m.customer_id=$1`,[customerId]),
    query(`select bureau_score from credit_bureau_checks where customer_id=$1 and bureau_score is not null order by coalesce(completed_at,created_at) desc limit 1`,[customerId]),
    query(`select score from internal_risk_scores where customer_id=$1 order by created_at desc limit 1`,[customerId]),
    query(`select count(*)::int count from loans where customer_id=$1`,[customerId])
  ])
  const x=contrib.rows[0]||{}, total=Number(x.total||0), paid=Number(x.paid||0)
  return {contribution_count:total,contribution_paid_count:paid,contribution_missed_count:Number(x.missed||0),contribution_on_time_rate:total?Math.round((paid/total)*10000)/100:0,bureau_score:Number(bureau.rows[0]?.bureau_score||0),prior_risk_score:Number(risk.rows[0]?.score||0),loan_count:Number(loans.rows[0]?.count||0)}
}
export async function evaluateCustomer(customerId,userId,loanId=null,ruleSetId=null){
  const metrics=await customerMetrics(customerId)
  let set
  if(ruleSetId) set=(await query(`select * from decision_rule_sets where id=$1`,[ruleSetId])).rows[0]
  else set=(await query(`select * from decision_rule_sets where code='AIBLE-CREDIT' order by case status when 'published' then 0 else 1 end,version desc limit 1`)).rows[0]
  if(!set) throw new Error('No AIBLE credit rule set is configured')
  const rules=(await query(`select * from decision_rules where rule_set_id=$1 and active=true order by priority,created_at`,[set.id])).rows
  let score=500,decision='manual_review',routeRole=null; const matched=[]
  for(const r of rules){if(!allowedMetrics.has(r.metric_key))continue; if(compare(metrics[r.metric_key],r.operator,r.compare_value)){matched.push({rule_code:r.rule_code,name:r.name,metric:r.metric_key,actual:metrics[r.metric_key],operator:r.operator,threshold:Number(r.compare_value),action:r.action_type,value:r.action_value}); if(r.action_type==='add_points')score+=Number(r.action_value||0);if(r.action_type==='subtract_points')score-=Number(r.action_value||0);if(r.action_type==='set_decision')decision=r.action_value;if(r.action_type==='manual_review')decision='manual_review';if(r.action_type==='route_role')routeRole=r.action_value}}
  score=Math.max(0,Math.min(1000,Math.round(score))); const band=score>=750?'low':score>=650?'moderate':score>=550?'elevated':'high'
  const run=(await query(`insert into decision_runs(customer_id,loan_id,rule_set_id,rule_set_version,input_snapshot,matched_rules,score,risk_band,decision,route_role,evaluated_by) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id`,[customerId,loanId,set.id,set.version,JSON.stringify(metrics),JSON.stringify(matched),score,band,decision,routeRole,userId])).rows[0]
  await query(`insert into credit_events(customer_id,event_type,source_type,source_id,status,data) values($1,'RULE_DECISION','decision_run',$2,$3,$4) on conflict(source_type,source_id,event_type) do nothing`,[customerId,run.id,decision,JSON.stringify({score,risk_band:band,decision,matched_rules:matched,metrics,rule_set:set.code,version:set.version})])
  return {run_id:run.id,score,risk_band:band,decision,route_role:routeRole,metrics,matched_rules:matched,rule_set:{code:set.code,name:set.name,version:set.version,status:set.status}}
}
