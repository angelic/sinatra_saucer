require 'flyingsaucer4r'
require 'java'

class PDF
  class UserAgent < org.xhtmlrenderer.pdf.ITextUserAgent
    def initialize(output_device)
      super
    end
 
    def resolveURI(uri)
      if uri =~ /^\//
        super(uri[1..uri.length])
      else
        super(uri)
      end
    end
    alias :resolve_uri :resolveURI
  end
 
  class << self
    def generate(xhtml, path = '.')
      dom = create_java_dom(xhtml)
      estimated_pdf_length = xhtml.length
      output = java.io.ByteArrayOutputStream.new(estimated_pdf_length)
 
      begin
        renderer = build_renderer(dom, path)
        renderer.create_pdf(output)
      ensure
        output.close
      end
 
      return String.from_java_bytes(output.to_byte_array)
    end
 
    private
    def create_java_dom(s)
      builder = javax.xml.parsers.DocumentBuilderFactory.new_instance.new_document_builder
      builder.parse(java.io.ByteArrayInputStream.new(s.to_java_bytes))
    end
 
    def path_to_url(path)
      java.io.File.new(path).to_uri.to_url.to_string
    end

    def build_renderer(dom, path)
      renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
      agent = UserAgent.new(renderer.output_device)
      agent.shared_context = renderer.shared_context
      renderer.shared_context.user_agent_callback = agent
      renderer.set_document(dom, path_to_url(path))
      renderer.layout
      renderer
    end
  end
end
