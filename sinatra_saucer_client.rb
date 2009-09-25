module SinatraSaucerClient
  require 'net/http'
  require 'uri'
  require 'zip/zip'

  SINATRA_SAUCER_URL = 'http://localhost:9292'
  STYLESHEETS_DIR = File.join(RAILS_ROOT, 'public', 'stylesheets', 'pdfs', '*')
  IMAGES_DIR = File.join(RAILS_ROOT, 'public', 'images', 'pdfs', '*')
  TEMP = File.join(RAILS_ROOT, 'tmp')

  def render_pdf(xhtml)
    tempfile = tmp_file
    pdf = nil
    begin
      url = URI.parse(SINATRA_SAUCER_URL)
      create_zip(tempfile, xhtml)
      data = File.open(tempfile, "rb") {|f| f.read}
      post_params = {:raw_data => data}
      @res = Net::HTTP.post_form(url, post_params)
      pdf = @res.body
      unless @cache.blank?
        @cache.pdf = pdf
        @cache.save
      end
    ensure
      File.delete(tempfile) rescue nil
    end
    pdf
  end

  def create_zip(tempfile, html)
    Zip::ZipFile.open(tempfile, Zip::ZipFile::CREATE) do |zipfile|
      add_html_to_zip(zipfile, html)
      add_stylesheets_to_zip(zipfile)
      add_images_to_zip(zipfile)
    end
  end

  def add_html_to_zip(zipfile, html)
    zipfile.get_output_stream("pdf.html") {|z| z.puts html}
  end

  def add_stylesheets_to_zip(zipfile)
    add_dir_to_zip(zipfile, STYLESHEETS_DIR, "stylesheets/forms")
  end

  def add_images_to_zip(zipfile)
    add_dir_to_zip(zipfile, IMAGES_DIR, "images/forms")
  end

  def add_dir_to_zip(zipfile, from, to)
    zipfile.mkdir(to)
    Dir.glob(from).each do |filename|
      File.open(filename) do |f|
        write_file = "#{to}/#{File.basename(filename)}"
        zipfile.get_output_stream(write_file) {|z| z.puts f.read}
      end
    end
  end

  def tmp_file
    File.join(TEMP, "pdf_#{Time.now.to_f}.zip")
  end
end
