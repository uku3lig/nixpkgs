{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.reposilite;
  format = pkgs.formats.cdn { };

  useEmbeddedDb = cfg.database.type == "sqlite" || cfg.database.type == "h2";
  usePostgres = cfg.database.type == "postgresql";

  dbString =
    if useEmbeddedDb then
      "${cfg.database.type} ${cfg.database.path}"
    else
      "${cfg.database.type} ${cfg.database.host}:${builtins.toString cfg.database.port} ${cfg.database.dbname} ${cfg.database.user} $dbPass";

  generatedEnv = "${cfg.workingDirectory}/reposilite_generated.env";
  configFile = format.generate "reposilite.cdn" cfg.settings;
in
{
  # TODO proper database setup
  # TODO plugins
  # TODO ACME
  # TODO figure out how to handle first token generation
  # TODO extraParams?
  # TODO tests (add to passthru)
  # TODO meta
  options.services.reposilite = {
    enable = lib.mkEnableOption "Reposilite";
    package = lib.mkPackageOption pkgs "reposilite" { };

    workingDirectory = lib.mkOption {
      type = lib.types.path;
      description = ''
        Working directory for Reposilite.
      '';
      default = "/var/lib/reposilite";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = ''
        The user to run Reposilite under.
      '';
      default = "reposilite";
    };

    group = lib.mkOption {
      type = lib.types.str;
      description = ''
        The group to run Reposilite under.
      '';
      default = "reposilite";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Whether to open the firewall ports for Reposilite. If SSL is enabled, its port will be opened too.
      '';
      default = false;
    };

    database = {
      type = lib.mkOption {
        type = lib.types.enum [
          "h2"
          "mariadb"
          "mysql"
          "postgresql"
          "sqlite"
        ];
        description = ''
          Database engine to use.
        '';
        default = "sqlite";
      };

      path = lib.mkOption {
        type = lib.types.str;
        description = ''
          Path to the embedded database file. Set to `--temporary` to use an in-memory database.
        '';
        default = "reposilite.db";
      };

      host = lib.mkOption {
        type = lib.types.str;
        description = ''
          Database host address.
        '';
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = lib.types.port;
        description = ''
          Database TCP port.
        '';
        defaultText = ''
          if type == "postgresql" then 5432 else 3306
        '';
        default = if usePostgres then config.services.postgresql.settings.port else 3306;
      };

      dbname = lib.mkOption {
        type = lib.types.str;
        description = ''
          Database name.
        '';
        default = "reposilite";
      };

      user = lib.mkOption {
        type = lib.types.str;
        description = ''
          Database user.
        '';
        default = "reposilite";
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        description = ''
          Path to the file containing the password for the database connection.
          This file must be readable by {option}`services.reposilite.user`.
        '';
        default = null;
      };
    };

    keyPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = ''
        Path the the file containing the password used to unlock the Java KeyStore file specified in {option}`services.reposilite.settings.keyPath`.
        This file must be readable my {option}`services.reposilite.user`.
      '';
      default = null;
    };

    settings = lib.mkOption {
      description = "Configuration written to the reposilite.cdn file";
      default = { };
      type = lib.types.submodule {
        freeformType = format.type;
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = ''
              The hostname to bind to. Set to `0.0.0.0` to accept connections from everywhere, or `127.0.0.1` to restrict to localhost."
            '';
            default = "0.0.0.0";
            example = "127.0.0.1";
          };

          port = lib.mkOption {
            type = lib.types.port;
            description = ''
              The TCP port to bind to.
            '';
            default = 3000;
          };

          database = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = ''
              Database connection string. Please use {option}`services.reposilite.database` instead.
              See https://reposilite.com/guide/general#local-configuration for valid values.
            '';
            default = null;
          };

          sslEnabled = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to listen for encrypted connections on {option}`settings.sslPort`.
            '';
            default = false;
          };

          sslPort = lib.mkOption {
            type = lib.types.port; # cant be null
            description = "SSL port to bind to. SSL needs to be enabled explicitly via {option}`settings.enableSsl`.";
            default = 443;
          };

          # TODO: option for ACME
          keyPath = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = ''
              Path to the .jsk KeyStore or paths to the PKCS#8 certificate and private key, separated by a space (see example).
              You can use `''${WORKING_DIRECTORY}` to refer to paths relative to Reposilite's working directory.
              If you are using a Java KeyStore, don't forget to specify the password via the {var}`REPOSILITE_LOCAL_KEYPASSWORD` environment variable.
              See https://reposilite.com/guide/ssl for more information on how to set SSL up.
            '';
            default = null;
            example = "\${WORKING_DIRECTORY}/cert.pem \${WORKING_DIRECTORY}/key.pem";
          };

          keyPassword = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = ''
              Plaintext password used to unlock the Java KeyStore set in {option}`services.reposilite.settings.keyPath`.
              WARNING: this option is insecure and should not be used to store the password.
              Consider using {option}`services.reposilite.keyPasswordFile` instead.
            '';
            default = null;
          };

          enforceSsl = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to redirect all traffic to SSL.
            '';
            default = false;
          };

          webThreadPool = lib.mkOption {
            type = lib.types.ints.between 5 65535;
            description = ''
              Maximum amount of threads used by the core thread pool. (min: 5)
              The web thread pool handles the first few steps of incoming HTTP connections, tasks are redirected as soon as possible to the IO thread pool.
            '';
            default = 16;
          };

          ioThreadPool = lib.mkOption {
            type = lib.types.ints.between 2 65535;
            description = ''
              The IO thread pool handles all tasks that may benefit from non-blocking IO. (min: 2)
              Because most tasks are redirected to IO thread pool, it might be a good idea to keep it at least equal to web thread pool.
            '';
            default = 8;
          };

          databaseThreadPool = lib.mkOption {
            type = lib.types.ints.positive;
            description = ''
              Maximum amount of concurrent connections to the database. (one per thread)
              Embedded databases (sqlite, h2) do not support truly concurrent connections, so the value will always be `1` if they are used.
            '';
            default = 1;
          };

          compressionStrategy = lib.mkOption {
            type = lib.types.enum [
              "none"
              "gzip"
            ];
            description = ''
              Compression algorithm used by this instance of Reposilite.
              `none` reduces usage of CPU & memory, but requires transfering more data.
            '';
            default = "none";
          };

          idleTimeout = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Default idle timeout used by Jetty.
            '';
            default = 30000;
          };

          bypassExternalCache = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Add cache bypass headers to responses from /api/* to avoid issues with proxies such as Cloudflare.
            '';
            default = true;
          };

          cachedLogSize = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Amount of messages stored in the cache logger.
            '';
            default = 50;
          };

          defaultFrontend = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to enable the default included frontend with a dashboard.
            '';
            default = true;
          };

          basePath = lib.mkOption {
            type = lib.types.str;
            description = ''
              Custom base path for this Reposilite instance.
              It is not recommended changing this, you should instead prioritize using a different subdomain.
            '';
            default = "/";
          };

          debugEnabled = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to enable debug mode.
            '';
            default = false;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.sslEnabled -> cfg.settings.keyPath != null;
        message = ''
          Reposilite was configured to enable SSL, but no valid paths to certificate files were provided via `settings.keyPath`.
          Read more about SSL certificates here: https://reposilite.com/guide/ssl
        '';
      }
      {
        assertion = cfg.settings.enforceSsl -> cfg.settings.sslEnabled;
        message = "You cannot enforce SSL if SSL is not enabled.";
      }
      {
        assertion = !useEmbeddedDb -> cfg.database.passwordFile != null;
        message = "You need to set `services.reposilite.database.passwordFile` when using a shared database.";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    users = {
      groups.${cfg.group} = { };
      users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall (
      [ cfg.settings.port ] ++ (lib.optional cfg.settings.sslEnabled cfg.settings.sslPort)
    );

    systemd.services.reposilite = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      preStart = ''
        touch "${generatedEnv}"

        ${lib.optionalString (cfg.settings.database == null) ''
          ${lib.optionalString (cfg.database.passwordFile != null) "dbPass=$(<${cfg.database.passwordFile})"}
          echo "REPOSILITE_LOCAL_DATABASE=\"${dbString}\"" >> ${generatedEnv}
        ''}

        ${lib.optionalString (cfg.keyPasswordFile != null && cfg.settings.keyPassword == null) ''
          echo "REPOSILITE_LOCAL_KEYPASSWORD=\"$(<${cfg.keyPasswordFile})\"" >> ${generatedEnv}
        ''}
      '';

      postStart = ''
        rm ${generatedEnv}
      '';

      serviceConfig = lib.mkMerge [
        (lib.mkIf (lib.strings.hasPrefix "/var/lib/" cfg.workingDirectory) {
          StateDirectory = lib.last (lib.splitString "/" cfg.workingDirectory);
          StateDirectoryMode = "700";
        })
        {
          Type = "simple";
          Restart = "always";

          ExecStart = "${lib.getExe cfg.package} --local-configuration ${configFile} --local-configuration-mode none --working-directory ${cfg.workingDirectory}";

          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.workingDirectory;
          EnvironmentFile = "-${generatedEnv}";

          # TODO better hardening
          LimitNOFILE = "1048576";
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        }
      ];
    };
  };
}
