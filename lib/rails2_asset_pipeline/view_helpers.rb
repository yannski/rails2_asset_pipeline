module Rails2AssetPipeline
  module ViewHelpers
    class << self
      attr_accessor :ignored_folders # e.g. 'images'
    end

    # Overwrite rails helper to use pipeline path for all relative assets
    # args: source, 'javascripts', 'js'
    def compute_public_path(*args)
      source = args[0]
      ignored_folders = Rails2AssetPipeline::ViewHelpers.ignored_folders
      source_is_relative = (
        source.is_a?(String) and
        source =~ /^[\w\-]+(\/|\.|$)/ and # xxx or xxx.js or xxx/yyy, not /xxx or http://
        not (ignored_folders and ignored_folders.include?(args[1]))
      )

      if source_is_relative
        source = "#{source}.#{args[2]}" unless source.include?(".")
        super(asset_path(source), *args[1..-1])
      else
        super
      end
    end

    def rails_asset_id(file)
      if file.start_with?("/assets/")
        nil
      else
        super
      end
    end

    def asset_path(asset)
      asset_with_id = if Rails2AssetPipeline.static?
        manifest = "#{Rails.root}/public/assets/manifest.json"
        raise "No dynamic assets available and no manifest found, run rake assets:precompile" unless File.exist?(manifest)
        @sprockets_manifest ||= Sprockets::Manifest.new(Rails2AssetPipeline.env, manifest)
        @sprockets_manifest.assets[asset] || "NOT_FOUND_IN_MANIFEST"
      else
        data = Rails2AssetPipeline.env[asset]
        data ? "#{asset}?#{data.mtime.to_i}" : "NOT_FOUND_IN_ASSETS"
      end

      "/assets/#{asset_with_id}"
    end
    module_function :asset_path
  end
end
