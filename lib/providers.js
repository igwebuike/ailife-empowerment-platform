export const providers = {
  creditRegistry: { name:'CreditRegistry', enabled:process.env.CREDIT_REGISTRY_LIVE==='true', configured:Boolean(process.env.CREDIT_REGISTRY_BASE_URL && process.env.CREDIT_REGISTRY_API_KEY) },
  yellowCard: { name:'Yellow Card', enabled:process.env.YELLOW_CARD_LIVE==='true', configured:Boolean(process.env.YELLOW_CARD_BASE_URL && process.env.YELLOW_CARD_API_KEY) },
  proofLedger: { name:'AIBLE Proof', enabled:process.env.BLOCKCHAIN_ANCHOR_ENABLED==='true', configured:Boolean(process.env.BLOCKCHAIN_RPC_URL) }
}
export async function yellowCardRequest(path, options={}){
  if(!providers.yellowCard.enabled || !providers.yellowCard.configured) throw new Error('Yellow Card is not enabled/configured')
  return fetch(`${process.env.YELLOW_CARD_BASE_URL}${path}`, {...options, headers:{'Content-Type':'application/json','Authorization':`Bearer ${process.env.YELLOW_CARD_API_KEY}`,...options.headers}})
}
