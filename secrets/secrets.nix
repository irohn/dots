let
  github = builtins.fromJSON (builtins.readFile ./github.json);
in {
  "bitwarden-master-password.age".publicKeys = github;
  "anthropic-api-key.age".publicKeys = github;
  "gemini-api-key.age".publicKeys = github;
  "openai-api-key.age".publicKeys = github;
}
