# assistant.nvim

**assistant.nvim** is a Neovim plugin written in Lua that allows you to chat with language models via [Ollama](https://ollama.com), retaining context between conversations. 

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/iuga/assistant.nvim/lint-test.yml?branch=main&style=flat)

## Features

- Chat with language models directly from Neovim.
- Retain context across multiple interactions with the model.
- Flexible and customizable configuration options.

## Requirements

- Neovim 0.5+ (for Lua support)
- [Ollama](https://ollama.com) 

## Installation

Add the following to your Lazy.nvim plugin list:

```lua
{
  "iuga/assistant.nvim",
  config = function()
    require("assistant").setup({
      model = "gemma2:27b"
    })
  end
}
```
## Usage

To select the model to use:
```
:AssistantChooseModel
```

Then, to start a conversation with the model, run the following command inside Neovim:
```
:AssistantChat
```
For further commands and customization options, check the documentation in the plugin.

## Contributing

Feel free to submit issues, feature requests, or pull requests on GitHub.

## License

This project is licensed under the MIT License. See LICENSE for more details.
