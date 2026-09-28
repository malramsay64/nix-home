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
          # Multimodal (mmproj loaded) dense reasoning model. Served with 64K of
          # its 256K max context (kubelab apps/services/llm
          # qwen3827bContextSize) to fit the 16GB card.
          id = "qwen3.8-27b";
          name = "Qwen3.8 27B";
          reasoning = true;
          input = [ "text" "image" ];
          contextWindow = 65536;
          # Kept well under half the window so replies don't crowd out context.
          maxTokens = 16384;
        }
        { id = "gemma4-12b"; name = "Gemma 4 12B"; }
      ];
    };
  };
}
