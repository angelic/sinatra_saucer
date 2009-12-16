require 'pdf_generator'
require 'pdf_concatenator'

class PDF
  extend PdfGenerator
  extend PdfConcatenator
end
