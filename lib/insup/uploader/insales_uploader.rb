require 'base64'
require_relative '../insales'

class Insup::Uploader::InsalesUploader < Insup::Uploader

  def upload_new_file file
    asset = find_asset file

    if !asset.nil?
      upload_modified_file file
      return
    end

    puts "Creating #{file.path}"

    configure_api
    asset_type = get_asset_type file.path

    if(!asset_type)
      raise "Cannot determine asset type for file #{file.path}"
    end

    file_contents = File.read(file.path)

    asset = InsalesApi::Asset.create({
      name: file.file_name,
      attachment: Base64.encode64(file_contents),
      theme_id: @config['theme_id'],
      type: asset_type
    })
  end

  def upload_modified_file file
    configure_api
    asset = find_asset file

    puts "Updating #{file.path}"

    if !asset
      raise "Cannot find remote counterpart for file #{file.path}"
    end

    file_contents = File.read(file.path)

    if asset.content_type.start_with? 'text/'
      asset.update_attribute(:content, file_contents)
    else
      asset.destroy
      asset_type = get_asset_type file.path
      asset = InsalesApi::Asset.create({
      name: file.file_name,
      attachment: Base64.encode64(file_contents),
      theme_id: @config['theme_id'],
      type: asset_type
    })
    end
  end

  def remove_file file
    configure_api
    asset = find_asset file
    if !asset
      raise "Cannot find remote counterpart for file #{file.path}"
    end

    asset.destroy
  end

private
  ASSET_TYPE_MAP = {
    'media/' => 'Asset::Media',
    'snippets/' => 'Asset::Snippet',
    'templates/' => 'Asset::Template'
  }.freeze


  def find_asset file
    asset_type = get_asset_type file.path

    if(!asset_type)
      raise "Cannot determine asset type for file #{file.path}"
    end

    assets = assets_list

    files = assets.select  do |el|
      el.type == asset_type && (el.human_readable_name == file.file_name || el.name == file.file_name)
    end

    if files && !files.empty?
      return files.first
    else
      return nil
    end
  end

  def get_asset_type path
    res = nil
    ASSET_TYPE_MAP.each do |k,v|
      if path.start_with? k
        res = v
        break
      end
    end

    return res
  end

  def configure_api
    if !@has_api
      active_resource_logger = Logger.new('log/active_resource.log', 'daily')
      active_resource_logger.level = Logger::DEBUG
      ActiveResource::Base.logger = active_resource_logger

      @has_api = ::Insup::Insales::Base.configure(@config['api_key'], @config['subdomain'], @config['password'])
    end
  end

  def theme
    configure_api
    @theme ||= InsalesApi::Theme.find(@config['theme_id'])
  end

  def assets_list
    configure_api
    @assets_list ||= theme.assets.to_a
    # @assets_list.each {|x| puts x.inspect}
    # @assets_list
  end

  def get_asset file
    configure_api
    asset = find_asset file

    if !asset
      raise "Cannot find remote counterpart for file #{file.path}"
    end

    InsalesApi::Asset.find(asset.id, params: {theme_id: @config['theme_id']})
  end

end
