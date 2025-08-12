{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      keybind = [
        "super+h=text:\\x02p"
        "super+l=text:\\x02n"
        "super+one=text:\\x021"
        "super+two=text:\\x022"
        "super+three=text:\\x023"
        "super+four=text:\\x024"
        "super+five=text:\\x025"
        "super+six=text:\\x026"
        "super+seven=text:\\x027"
        "super+eight=text:\\x028"
        "super+nine=text:\\x029"
        "super+zero=text:\\x020"
        "alt+one=text:\\x021"
        "alt+two=text:\\x022"
        "alt+three=text:\\x023"
        "alt+four=text:\\x024"
        "alt+five=text:\\x025"
        "alt+six=text:\\x026"
        "alt+seven=text:\\x027"
        "alt+eight=text:\\x028"
        "alt+nine=text:\\x029"
        "alt+zero=text:\\x020"
      ];
      window-decoration = false;
      window-padding-balance = true;
    };
  };
}
