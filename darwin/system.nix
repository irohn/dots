{
  #  All the configuration options are documented here:
  #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
  #  System options are documented here:
  #    https://mynixos.com/nix-darwin/options/system
  system = {
    keyboard = {
      enableKeyMapping = true; # enable key remapping
      remapCapsLockToEscape = true; # remap Caps Lock to Escape
    };
    defaults = {
      NSGlobalDomain = {
        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution
        NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction
        NSWindowShouldDragOnGesture = true; # allow dragging windows with ctrl + cmd + drag
        _HIHideMenuBar = false; # hide menu bar
      };
      dock = {
        autohide = true; # auto-hide dock
        orientation = "bottom";
        show-process-indicators = false; # hide process indicators
        show-recents = false;
        static-only = true;
      };
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true; # show status bar
        FXEnableExtensionChangeWarning = false;
      };
      trackpad = {
        Clicking = true; # enable tap to click
        TrackpadRightClick = true; # enable two finger right click
      };
      spaces = {
        spans-displays = true;
      };
      menuExtraClock.Show24Hour = true; # show 24 hour clock
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };
      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = true; # show full name in login window
      };
    };
  };
}
