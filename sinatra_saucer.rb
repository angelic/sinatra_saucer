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
    @pdf = if File.exist?(File.join(@dir, 'MANIFEST'))
      create_pdf_from_multiple_files    
    else
      create_pdf_from_single_file('pdf.html')
    end
  end

  def create_pdf_from_single_file(file_name)
    pdf = File.join(@dir, file_name)
    PDF.generate(File.read(pdf), @dir)
  end

  def create_pdf_from_multiple_files
    pdf_files = []
    manifest_file = File.join(@dir, 'MANIFEST')
    files = File.read(manifest_file).split("\n")
    process_files_from_manifest(files, pdf_files)
    output_file = File.join(@dir, "concatenated_sinatra_pdf.pdf")
    PDF.concatenate(pdf_files, output_file)
    File.read(output_file)
  end

  def process_files_from_manifest(files, pdf_files)
    files.each do |file_name|
      if file_name =~ /pdf$/
        pdf_files << File.join(@dir, file_name)
      else
        temp_pdf = File.join(@dir, "temp_sinatra_pdf_#{pdf_files.size}")
        pdf_files << temp_pdf
        File.open(temp_pdf, "w") do |f|
          pdf = create_pdf_from_single_file(file_name)
          f.write(pdf)
        end
      end
    end
  end

  def delete_files
    FileUtils.rm_rf(@dir, :secure => true)
  end
end
