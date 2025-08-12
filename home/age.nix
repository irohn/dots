{config, ...}: {
  age.identityPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

  age.secrets."anthropic-api-key.age".file = ../secrets/anthropic-api-key.age;
  age.secrets."bitwarden-master-password.age".file = ../secrets/bitwarden-master-password.age;
  age.secrets."gemini-api-key.age".file = ../secrets/gemini-api-key.age;
  age.secrets."openai-api-key.age".file = ../secrets/openai-api-key.age;
}
