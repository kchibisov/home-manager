{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        abc = {
          identityFile = null;
          proxyJump = "jump-host";
        };

        ordered = hm.dag.entryAfter [ "xyz" ] { port = 1; };

        xyz = {
          identityFile = "file";
          serverAliveInterval = 60;
          serverAliveCountMax = 10;
          localForwards = [{
            bind.port = 8080;
            host.address = "10.0.0.1";
            host.port = 80;
          }];
          remoteForwards = [
            {
              bind.port = 8081;
              host.address = "10.0.0.2";
              host.port = 80;
            }
            {
              bind.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
              host.address = "/run/user/1000/gnupg/S.gpg-agent";
            }
          ];
          dynamicForwards = [{ port = 2839; }];
          setEnv = {
            FOO = "foo12";
            BAR = "_bar_ 42";
          };
        };

        "* !github.com" = {
          identityFile = [ "file1" "file2" ];
          port = 516;
        };
      };
    };

    home.file.assertions.text = builtins.toJSON
      (map (a: a.message) (filter (a: !a.assertion) config.assertions));

    test.stubs.openssh = { };

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./match-blocks-attrs-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
