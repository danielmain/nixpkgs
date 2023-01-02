import ./make-test-python.nix ({ pkgs, lib, ...} : {
  name = "gnome-flashback";
  meta = with lib; {
    maintainers = teams.gnome.members ++ [ maintainers.chpatrick ];
  };

  nodes.machine = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
  in

    { imports = [ ./common/user-account.nix ];

      services.xserver.enable = true;

      services.xserver.displayManager = {
        gdm.enable = true;
        gdm.debug = true;
        autoLogin = {
          enable = true;
          user = user.name;
        };
      };

      services.xserver.desktopManager.gnome.enable = true;
      services.xserver.desktopManager.gnome.debug = true;
      services.xserver.desktopManager.gnome.flashback.enableMetacity = true;
      services.xserver.displayManager.defaultSession = "gnome-flashback-metacity";
    };

  testScript = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
    uid = toString user.uid;
    xauthority = "/run/user/${uid}/gdm/Xauthority";
  in ''
      with subtest("Login to GNOME Flashback with GDM"):
          machine.wait_for_x()
          # Wait for alice to be logged in"
          machine.wait_for_unit("default.target", "${user.name}")
          machine.wait_for_file("${xauthority}")
          machine.succeed("xauth merge ${xauthority}")
          # Check that logging in has given the user ownership of devices
          assert "alice" in machine.succeed("getfacl -p /dev/snd/timer")

      with subtest("Wait for Metacity"):
          machine.wait_until_succeeds(
              "pgrep metacity"
          )
          machine.sleep(20)
          machine.screenshot("screen")
    '';
})
