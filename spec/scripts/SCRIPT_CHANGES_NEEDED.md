# Script changes required before specs will pass

## --no-load flag (print skipped command, don't run it)
Pattern: when --no-load is set, print something like:
  puts "No-load option has disabled the following that is normally run:"
  puts "  #{command}"

Scripts needing --no-load added:
- parse-member-links.rb  (calls: mpinfoin.pl links)
- wikipedia.rb           (calls: mpinfoin.pl links)

Scripts that already have --no-load:
- parse-members.rb       (calls: xml2db.pl --members) — needs the print-when-skipped message added
- parse-speeches.rb      (calls: xml2db.pl --debates) — needs the print-when-skipped message added
- postcodes.rb           (skips DB INSERT)             — needs the print-when-skipped message added

## --limit=N flag (cap number of people/entries processed)
Scripts needing --limit added:
- member-images.rb       (caps People#download_images loop)
- parse-member-links.rb  (caps morph.io result loop)
- wikipedia.rb           (caps people loop)

## --output-dir=PATH flag (redirect XML output for testing)
Scripts needing --output-dir added:
- parse-member-links.rb  (currently writes to conf.members_xml_path)
- parse-members.rb       (currently writes to conf.members_xml_path)
- parse-speeches.rb      (currently writes to conf.xml_path/scrapedxml/...)
- sitemap.rb             (currently writes to MySociety::Config paths)
- wikipedia.rb           (currently writes to conf.members_xml_path)
