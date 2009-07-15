require 'rubygems'
require 'ftools'
require 'zip/zip'
require 'pdf'
require 'sinatra'
require 'erb'

get '/' do
  erb :index
end

post '/' do
  begin
    create_pdf_from_zip
    content_type 'application/pdf'
    @pdf
  rescue Exception => e
    puts e.message
    puts e.backtrace
    error(500, 'There was an error')
  ensure
    delete_files rescue nil
  end
end

helpers do
  @@i = 0
  TEMP = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))

  def create_pdf_from_zip
    @dir = tmp_dir
    @zip = File.join(@dir, 'data.zip')
    save_file
    unzip_file
    create_pdf
  end

  def tmp_dir
    @@i += 1
    File.join(TEMP, "#{Time.now.to_i}#{@@i}")
  end

  def save_file
    File.makedirs(@dir)
    File.open(@zip, "w") do |f|
      data = params[:raw_data] || params[:data][:tempfile].read
      f.write(data)
    end
  end

  def unzip_file
    Zip::ZipInputStream::open(@zip) do |io|
      while(entry = io.get_next_entry) do
        next if entry.directory?
        file = File.join(@dir, entry.name)
        next if (File.exist?(file) && File.directory?(file)) || file =~ /\/$/
        FileUtils.mkdir_p(File.dirname(file))
        File.open(file, "w") do |f|
          f.write(io.read)
        end
      end
    end
  end

  def create_pdf
    pdf = File.join(@dir, 'pdf.html')
    File.open(pdf, "r") do |f|
      @pdf = PDF.generate(f.read, @dir)
    end
  end

  def delete_files
    FileUtils.rm_rf(@dir, :secure => true)
  end
end
