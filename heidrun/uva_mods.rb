# coding: utf-8

#   <accessCondition type="restrictionOnAccess" displayLabel="Access to the Collection"/>;
#   <accessCondition type="useAndReproduction" displayLabel="Use of the Collection">
rights_map = lambda do | record|
  rights = record['accessCondition']
    .match_attribute(:type, 'restrictionOnAccess')
    .match_attribute(:displayLabel, 'Access to the Collection')

  rights.concat(record['accessCondition']
    .match_attribute(:type, 'useAndReproduction')
    .match_attribute(:displayLabel, 'Use of the Collection'))
end

# dcterms:subject
#   <subject authority="lcsh"><topic>;
#   <subject authority="lcsh"><name …><name Part>;
#   <name type="personal" authority="lcnaf"><namePart …>...
subject_map = lambda do |record|
  subjects = record['subject']
    .match_attribute(:authority, 'lcsh')
    .field('topic')

  subjects.concat(record['subject']
                    .match_attribute(:authority, 'lcsh')
                    .field('name', 'namePart'))

  subjects.concat(record['name']
                    .match_attribute(:name, 'personal')
                    .match_attribute(:authority, 'lcnaf')
                    .field('name', 'namePart'))
end


Krikri::Mapper.define(:uva_mods,
                      :parser => Krikri::ModsParser) do

  # edm:dataProvider
  #   <location><physicalLocation>
  dataProvider :class => DPLA::MAP::Agent do
    label record.field('location', 'physicalLocation')
  end

  # edm:isShownAt
  #   <location><url access="object in context">
  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('location', 'url')
              .match_attribute(:access, 'object in context')
  end

  # edm:preview
  #   <url access="preview">
  preview :class => DPLA::MAP::WebResource do
    uri record.field('location', 'url')
              .match_attribute(:access, 'preview'),
  end

  # edm:provider
  #   University of Virginia Library
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/uva'
    label 'University of Virginia Library'
  end

  # dpla:originalRecord
  #   DPLA
  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  # edm:hasView
  #   <PhysicalDescription><internetMediaType>
  hasView :class => DPLA::MAP::WebResource do
    format record.field('physicalDescription', 'internetMediaType')
  end

  # dpla:SourceResource
  sourceResource :class => DPLA::MAP::SourceResource do

    # dcterms:isPartOf
    #   <relatedItem type="series" ...><titleInfo><title>[IGNORE <nonSort>]
    collection :class => DPLA::MAP::Collection,
               :each => record.field('relatedItem')
                              .match_attribute(:type, 'series')
                              .field('titleInfo', 'title'),
               :as => :collection do
      title collection
    end
    # <nonSort> is a child of <titleInfo> so quietly ignored - JB

    # dcterms:creator
    #   <name type="personal" authority="lcnaf">
    #   or <name type="corporate" authority="lcnaf">
    creator :class => DPLA::MAP::Agent,
            :each => record.field('name')
                           .match_attribute(:authority, 'lcnaf')
                           .match_attribute(:type) { |type|
                              ['personal', 'corporate'].include?(type)
                            },
            :as => :creator do
      providedLabel creator
    end

    # dc:date
    #   <dateIssued keyDate="yes">[value] Date</dateIssued>
    #   NOTE: if value is "unknown," do not display
    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('dateIssued'),
         :as => :date do
      providedLabel date
    end
    # TODO - this is in collection-description-mods.xml
    #        not the item mods file. How to get it? -JB
    #        <mods:originInfo><mods:dateIssued>
    #        not seeing keyDate there either
    #        there is <originInfo><dateCreated> in the item
    #        which has keyDate

    # dcterms:description
    #   <physicalDescription><note displayLabel="condition">
    description record.field('physicalDescription', 'note')
                      .match_attribute(:displayLabel, 'condition')

    # dcterms:extent
    #   <physicalDescription><note displayLabel="size inches">
    extent record.field('physicalDescription', 'note')
                 .match_attribute(:displayLabel, 'size inches')

    # dc:format
    #   <physicalDescription>
    dcformat record.field('physicalDescription')

    # dcterms:identifier
    #   <identifier type="uri" ...>
    identifier record.field('identifier')
                     .match_attribute(:type, 'uri')

    # dcterms:spatial
    #   <originInfo><place><placeTerm …>
    spatial :class => DPLA::MAP::Place,
            :each => record.field('originInfo', 'place', 'placeTerm')
            :as => :place do
      providedLabel place
    end

    # dcterms:publisher
    #   <originInfo><publisher>
    publisher :class => DPLA::MAP::Agent,
              :each => record.field('originInfo', 'publisher')
              :as => :publisher do
      providedLabel publisher
    end

    # dc:rights
    #   <accessCondition type="restrictionOnAccess" displayLabel="Access to the Collection"/>;
    #   <accessCondition type="useAndReproduction" displayLabel="Use of the Collection">
    rights record.map(&rights_map).flatten

    # dcterms:subject
    #   <subject authority="lcsh"><topic>;
    #   <subject authority="lcsh"><name …><name Part>;
    #   <name type="personal" authority="lcnaf"><namePart …>...
    subject :class => DPLA::MAP::Concept,
            :each => record.map(&subject_map).flatten,
            :as => :subject do
      providedLabel subject
    end
    # <name Part> should be <namePart> - JB

    # dcterms:title
    #   <titleInfo> <mods:title>
    title record.field('titleInfo', 'title')
    # not sure why mods: is specified here - ignoring - JB

    # dcterms:type
    #   <typeOfResource...> DCMItype enrichment
    dctype record.field('typeOfResource')
  end

end