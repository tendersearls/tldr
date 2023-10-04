class TLDR
  class Watcher
    def watch config
      require_fs_watch!
      tldr_command = "#{"bundle exec " if defined?(Bundler)}tldr #{config.to_full_args(ensure_args: ["--i-am-being-watched"])}"
      command = "fswatch -o #{config.load_paths.reverse.join(" ")} | xargs -n1 -I{} #{tldr_command}"

      puts <<~MSG

        Watching for changes in #{config.load_paths.map(&:inspect).join(", ")}...

        When a file changes, TLDR will run this command:

        $ #{tldr_command}

      MSG

      exec command
    end

    private

    def require_fs_watch!
      `which fswatch`
      return if $?.success?

      warn <<~MSG
        Error: fswatch must be installed and on your PATH to run TLDR in --watch mode

        See: https://github.com/emcrisostomo/fswatch
      MSG
      exit 1
    end
  end
end
