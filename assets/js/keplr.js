export const connectKeplr = async () => {
  try {
    // Check if Keplr is installed
    if (!window.keplr) {
      throw new Error("wallet_not_found");
    }

    // Get chain config from Phoenix
    const chainId = window.chainConfig.chainId;
    
    // Request Keplr connection
    await window.keplr.enable(chainId);
    
    // Get the offline signer
    const offlineSigner = await window.keplr.getOfflineSigner(chainId);
    
    // Get user's account
    const accounts = await offlineSigner.getAccounts();
    const address = accounts[0].address;
    
    return { ok: true, address };
  } catch (error) {
    // Map Keplr errors to our error types
    switch(error.message) {
      case "wallet_not_found":
        return { ok: false, error: "wallet_not_found" };
      case "Request rejected":
        return { ok: false, error: "user_rejected" };
      default:
        return { ok: false, error: "network_error" };
    }
  }
}; 