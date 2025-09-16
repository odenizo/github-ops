import os
import json
import requests

class CopilotAgentSetup:
    """
    A class to automate the setup of the GitHub Copilot coding agent
    for a specific repository.
    """
    BASE_URL = "https://api.github.com"

    def __init__(self, repo_owner: str, repo_name: str, token: str):
        """
        Initializes the setup client.

        Args:
            repo_owner: The owner of the repository.
            repo_name: The name of the repository.
            token: A GitHub Personal Access Token with 'repo' scope.
        """
        self.repo_owner = repo_owner
        self.repo_name = repo_name
        self.repo_path = f"{repo_owner}/{repo_name}"
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json",
            "X-GitHub-Api-Version": "2022-11-28"
        }

    def _make_request(self, method, endpoint, **kwargs):
        """Helper function to make requests to the GitHub API."""
        url = f"{self.BASE_URL}{endpoint}"
        response = requests.request(method, url, headers=self.headers, **kwargs)
        response.raise_for_status()
        # Some successful responses have no content (e.g., PUT, DELETE)
        try:
            return response.json()
        except json.JSONDecodeError:
            return None

    def create_copilot_environment(self):
        """Creates the 'copilot' environment in the repository."""
        print(f"Creating 'copilot' environment in '{self.repo_path}'...")
        endpoint = f"/repos/{self.repo_path}/environments/copilot"
        try:
            self._make_request("PUT", endpoint)
            print("✅ 'copilot' environment created or already exists.")
        except requests.exceptions.HTTPError as e:
            print(f"❌ Failed to create environment: {e.response.text}")
            raise

    def set_environment_secret(self, secret_name: str, secret_value: str):
        """Creates or updates a secret in the 'copilot' environment."""
        from base64 import b64encode
        
        print(f"Setting secret '{secret_name}'...")
        
        # Get the public key for the environment
        try:
            key_endpoint = f"/repos/{self.repo_path}/environments/copilot/secrets/public-key"
            public_key_info = self._make_request("GET", key_endpoint)
            key = public_key_info['key']
            key_id = public_key_info['key_id']
        except requests.exceptions.HTTPError as e:
            print(f"❌ Failed to get public key for 'copilot' environment: {e.response.text}")
            raise

        # Encrypt the secret
        # This requires the 'pynacl' library: pip install pynacl
        from nacl import encoding, public
        public_key = public.PublicKey(key.encode("utf-8"), encoding.Base64Encoder())
        sealed_box = public.SealedBox(public_key)
        encrypted_value = b64encode(sealed_box.encrypt(secret_value.encode("utf-8"))).decode("utf-8")
        
        # Set the secret
        try:
            secret_endpoint = f"/repos/{self.repo_path}/environments/copilot/secrets/{secret_name}"
            data = {
                "encrypted_value": encrypted_value,
                "key_id": key_id
            }
            self._make_request("PUT", secret_endpoint, json=data)
            print(f"✅ Secret '{secret_name}' set successfully.")
        except requests.exceptions.HTTPError as e:
            print(f"❌ Failed to set secret '{secret_name}': {e.response.text}")
            raise
    
    def set_mcp_configuration(self, mcp_config: dict):
        """Sets the MCP configuration for the Copilot coding agent."""
        print("Setting MCP configuration for the coding agent...")
        endpoint = f"/repos/{self.repo_path}"
        # This uses an undocumented property on the repository object.
        data = {"copilot_mcp_configuration": json.dumps(mcp_config)}
        try:
            self._make_request("PATCH", endpoint, json=data)
            print("✅ MCP configuration set successfully.")
        except requests.exceptions.HTTPError as e:
            print(f"❌ Failed to set MCP configuration: {e.response.text}")
            raise

def main():
    # --- Configuration ---
    # Replace with the target repository's owner and name
    REPO_OWNER = "OWNER"
    REPO_NAME = "REPO"
    
    GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")

    if not GITHUB_TOKEN:
        raise ValueError("GITHUB_TOKEN environment variable not set.")

    # Secrets to be added to the 'copilot' environment
    # It's recommended to load these from a secure source or environment variables
    secrets_to_add = {
        "COPILOT_MCP_SUPABASE_ACCESS_TOKEN": os.getenv("SUPABASE_TOKEN", "your_default_supabase_token"),
        "COPILOT_MCP_EXA_API_KEY": os.getenv("EXA_API_KEY", "your_default_exa_key")
    }
    
    # MCP Configuration
    mcp_config = {
      "mcpServers": {
        "supabase": {
          "type": "local",
          "command": "npx",
          "args": ["-y", "@supabase-community/mcp-server@latest"],
          "env": { "SUPABASE_ACCESS_TOKEN": "COPILOT_MCP_SUPABASE_ACCESS_TOKEN" },
          "tools": ["*"]
        },
        "exa": {
          "type": "local",
          "command": "npx",
          "args": ["-y", "exa-mcp-server"],
          "env": { "EXA_API_KEY": "COPILOT_MCP_EXA_API_KEY" },
          "tools": ["web_search"]
        }
      }
    }
    # --- End of Configuration ---

    # Note: The script requires the 'pynacl' library for encryption.
    # Install it with: pip install pynacl
    
    setup = CopilotAgentSetup(REPO_OWNER, REPO_NAME, GITHUB_TOKEN)

    # 1. Create the environment
    setup.create_copilot_environment()

    # 2. Set secrets
    for name, value in secrets_to_add.items():
        if "your_default" in value:
            print(f"⚠️  Skipping secret '{name}' as it seems to be a default placeholder value.")
            continue
        setup.set_environment_secret(name, value)
        
    # 3. Set MCP configuration
    setup.set_mcp_configuration(mcp_config)

    print(f"\n🚀 Copilot agent setup complete for {REPO_OWNER}/{REPO_NAME}.")


if __name__ == "__main__":
    main()