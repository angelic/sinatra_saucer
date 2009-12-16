require 'flyingsaucer4r'
require 'java'

module PdfConcatenator
  Document = Java::ComLowagieText::Document
  PdfReader = Java::ComLowagieTextPdf::PdfReader
  PdfCopy = Java::ComLowagieTextPdf::PdfCopy
  PdfWriter = Java::ComLowagieTextPdf::PdfWriter
  SimpleBookmark = Java::ComLowagieTextPdf::SimpleBookmark

  def concatenate(input_paths, output_path)
    streams = {} # :writer, :document, :out_stream

    begin
      page_offset = 0
      master_bookmark_list = java.util.ArrayList.new
      input_paths.each do |input_path|
        reader = new_reader(input_path)
        streams = create_streams(reader, output_path) if streams.size == 0
        add_bookmarks_to_list(master_bookmark_list, reader, page_offset)
        copy_data(reader, streams[:writer])
        page_offset += reader.number_of_pages
      end

      add_bookmarks_to_pdf(master_bookmark_list, streams[:writer])
    ensure
      close_streams(streams)
    end
  end

  private
  def new_reader(input_path)
    reader = PdfReader.new(input_path)
    reader.consolidate_named_destinations
    reader
  end

  def add_bookmarks_to_list(master_bookmark_list, reader, page_offset)
    bookmarks = extract_bookmarks(reader, page_offset)
    master_bookmark_list.add_all(bookmarks) if bookmarks
  end

  def create_streams(reader, output_path)
    document = Document.new(reader.get_page_size_with_rotation(1))
    out_stream = java.io.FileOutputStream.new(output_path)
    writer = PdfCopy.new(document, out_stream)
    document.open
    writer.set_viewer_preferences(PdfWriter::PageModeUseOutlines)
    {:document => document, :writer => writer, :out_stream => out_stream}
  end

  def extract_bookmarks(reader, page_offset)
    bookmarks = SimpleBookmark.get_bookmark(reader)
    if bookmarks && page_offset > 0
      SimpleBookmark.shift_page_numbers(bookmarks, page_offset, nil)
    end
    bookmarks
  end

  def copy_data(reader, writer)
    copy_pages(reader, writer)
    copy_acro_form(reader, writer)
  end

  def copy_pages(reader, writer)
    (1..reader.number_of_pages).each do |page_no|
      writer.add_page(writer.get_imported_page(reader, page_no))
    end
  end

  def copy_acro_form(reader, writer)
    form = reader.get_acro_form
    writer.copy_acro_form(reader) if form
  end

  def add_bookmarks_to_pdf(master_bookmark_list, writer)
    if master_bookmark_list.size > 0
      collapse_bookmarks(master_bookmark_list)
      writer.set_outlines(master_bookmark_list)
    end
  end

  def collapse_bookmarks(bookmarks)
    bookmarks.each do |bookmark|
      bookmark.put("Open", "false")
      kids = bookmark.get("Kids")
      collapse_bookmarks(kids) if kids && kids.size() > 0
    end
  end

  def close_streams(streams)
    begin
      streams[:writer].close if streams[:writer]
      streams[:document].close if streams[:document]
    ensure
      streams[:out_stream].close if streams[:out_stream]
    end
  end
end
