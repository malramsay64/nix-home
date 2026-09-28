{ config }:
{
  providers = {
    litellm = {
      baseUrl = "https://llm.malramsay.com/v1";
      api = "openai-completions";
      # Resolved lazily by pi itself (cached for the process lifetime) via the
      # 1Password desktop app; the key never enters the agent's shell env.
      apiKey = ''!op read "op://Homelab/LLM/litellm-master-key"'';
      models = [
        {
          id = "qwen3.8-27b-tools";
          name = "Qwen3.8 27B (tools)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 128000;
          maxTokens = 32768;
        }
        { id = "qwen3.8-27b"; name = "Qwen3.8 27B"; }
        { id = "qwen3-27b"; name = "Qwen3 27B"; }
        { id = "qwen-coder"; name = "Qwen Coder"; }
        { id = "qwen-coder-tools"; name = "Qwen Coder (tools)"; }
        { id = "qwen-vl"; name = "Qwen VL (vision)"; input = [ "text" "image" ]; }
        { id = "gemma4"; name = "Gemma 4"; }
        { id = "gemma4-12b"; name = "Gemma 4 12B"; }
      ];
    };
  };
}
