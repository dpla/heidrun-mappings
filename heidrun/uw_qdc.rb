def uw_preview(identifier)
  id = identifier.rpartition(':').last.split('/')
  return nil if id.count != 2
  'http://cdm16786.contentdm.oclc.org/utils/getthumbnail/collection/' \
  "#{id[0]}/id/#{id[1]}"
end

Krikri::Mapper.define(:uw_qdc,
                      :parser => Krikri::QdcParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/washington'
    label 'University of Washington'
  end

  dataProvider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/washington'
    label 'University of Washington'
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier').last_value
  end

  preview :class => DPLA::MAP::WebResource do
    uri header.field('xmlns:identifier').first_value
         .map { |i| uw_preview(i.value) }
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    collection :class => DPLA::MAP::Collection,
               :each => header.field('xmlns:setSpec'), 
               :as => :coll do
      title coll
    end

    creator :class => DPLA::MAP::Agent,
            :each => record.field('dc:creator'),
            :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('dc:date').first_value,
         :as => :created do
      providedLabel created
    end

    description record.field('dc:description')

    dcformat record.fields('dc:format', 'dc:type', 'dcterms:medium')

    identifier record.field('dc:identifier')

    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('dc:language'),
             :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place,
            :each => record.fields('dc:coverage', 'dcterms:spatial'),
            :as => :place do
      providedLabel place
    end

    relation record.fields('dc:relation', 'dcterms:isPartOf')

    rights record.field('dc:rights')

    subject :class => DPLA::MAP::Concept,
            :each => record.field('dc:subject'),
            :as => :subject do
      providedLabel subject
    end

    temporal :class =>DPLA::MAP::TimeSpan,
    	     :each => record.field('dcterms:temporal'),
             :as => :temporal do
      providedLabel temporal
    end
    
    title record.fields('dc:title', 'dcterms:alternative')

    dctype record.fields('dc:type', 'dcterms:medium')
  end
end
