ruby-dxf-reader
===============

Parse DXF files into Ruby objects


dxf2ruby.rb - (C) 2011 jim.foltz@gmail.com

  
Branch 1.0+ is a simple translator which reads a .dxf and translates it into
a Ruby data-structure.

Branch 2.0+ parses a .dxf and builds a Dxf class hierarchy of objects.

Purpose
=======

 To parse .dxf files into something useful by Ruby using only built-in Ruby
 objects. The DXF file is converted into Ruby Hash, Array, Float, Fixnum, String objects. This library is meant to be a building-block for more advanced DXF processing using Ruby.
 

 **Quick Start**

    require 'dxf2ruby'
    dxf = Dxf2Ruby.parse("file.dxf")
    acad_version =  dxf['HEADER']['$ACADVER']
    dxf['ENTITIES'].each do |entity|
      draw(entity)
    end
    
    def draw(entity)
     case entity[0]
     when "POINT"
      draw_point(entity)
     when "LINE"
      draw_line(entity)
      end
     end

 Dxf2RUby may also be used on a command line to inspect a DXF file:

       $ dxf2ruby file.dxf | less

 **About**

 dxf2ruby returns a Ruby data structure from a .dxf file. Dxf2Ruby does not
 attempt to interpret the codes, but rather assembles the codes into Acad
 objects in the form of Ruby Hashes.

 The top-level data structure is a Hash of containers representing SECTIONS of
 the .dxf file.  Currently supported sections are the `HEADER`, `BLOCKS`, and
 `ENTITIES` sections. The top-level Hash looks as follows:

    {"HEADER"=>{...}, "BLOCKS"=>[...], "ENTITIES"=>[...]}


 **The HEADER Section**

The HEADER section is a Ruby Hash object. Reading the HEADER variables can be done as follows:

       header = dxf['HEADER']
       acad_version = header['$ACADVER'][1]



 **The BLOCKS Section**

 The `BLOCKS` section is a Ruby Array.


 **The ENTITIES Section**

 Acad entities are returned as Ruby Hashes.  A typical entity may look similar
 to the following Hash, which represents an Acad LINE entity:

    {0=>"LINE", 5=>"25", 100=>["AcDbEntity", "AcDbLine"], 8=>"0",
    6=>"CONTINUOUS", 62=>7, 10=>-4.672884, 20=>-0.816414, 30=>0.0,
    11=>-4.672884, 21=>-0.27178, 31=>0.0}

---

 About DXF (Notes from AutoCAD)

 DXF _Objects_ have no graphical representation. (aka nongraphical objects)

 DXF _Entities_ are graphical objects.

 Accommodating DXF files from future releases of AutoCAD(r) will be easier
 if you write your DXF processing program in a table-driven way, ignore
 undefined group codes, and make no assumptions about the order of group codes
 in an entity. With each new AutoCAD release, new group codes will be added to
 entities to accommodate additional features.
