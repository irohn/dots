{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "None";
        opacity = 0.99;
        blur = true;
        title = "Terminal";
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 15;
      };
      bell = {
        command = "None";
      };
      selection.save_to_clipboard = true;
      keyboard.bindings = [
        {
          key = "Back";
          mods = "Command";
          chars = "\\u0015";
        }
        {
          key = "Key1";
          mods = "Command";
          chars = "\\u001b1";
        }
        {
          key = "Key2";
          mods = "Command";
          chars = "\\u001b2";
        }
        {
          key = "Key3";
          mods = "Command";
          chars = "\\u001b3";
        }
        {
          key = "Key4";
          mods = "Command";
          chars = "\\u001b4";
        }
        {
          key = "Key5";
          mods = "Command";
          chars = "\\u001b5";
        }
        {
          key = "Key6";
          mods = "Command";
          chars = "\\u001b6";
        }
        {
          key = "Key7";
          mods = "Command";
          chars = "\\u001b7";
        }
        {
          key = "Key8";
          mods = "Command";
          chars = "\\u001b8";
        }
        {
          key = "Key9";
          mods = "Command";
          chars = "\\u001b9";
        }
        {
          key = "H";
          mods = "Command";
          chars = "\\u001bh";
        }
        {
          key = "L";
          mods = "Command";
          chars = "\\u001bl";
        }
      ];
    };
  };
}
