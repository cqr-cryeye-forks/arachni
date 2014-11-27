require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 14,
            Element::Link         => 14,
            Element::Cookie       => 14,
            Element::Header       => 14,
            Element::LinkTemplate => 14
        }
    end

    easy_test
end
