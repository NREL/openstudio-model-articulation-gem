# dxf2ruby.rb - (C) 2011 jim.foltz@gmail.com
#
#     This library is free software; you can redistribute it and/or
#     modify it under the terms of the GNU Lesser General Public
#     License as published by the Free Software Foundation; either
#     version 2.1 of the License, or (at your option) any later version.
#
#     This library is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     Lesser General Public License for more details.
#
#     You should have received a copy of the GNU Lesser General Public
#     License along with this library; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
# About DXF (Nots from AutoCAD)
#
# DXF _Objects_ have no graphical representation. (aka nongraphical objects)
# DXF _Entities_ are graphical objects.

# Accommodating DXF files from future releases of AutoCAD(r) will be easier
# if you write your DXF processing program in a table-driven way, ignore
# undefined group codes, and make no assumptions about the order of group codes
# in an entity. With each new AutoCAD release, new group codes will be added to
# entities to accommodate additional features.

# HISTORY
# 2013-10-3 Version 1.0
#  * Added LGPL License
#  * Uploaded to https://github.com/jimfoltz/ruby-dxf-reader
#

module Dxf2Ruby
  module_function

  def parse(filename)
    fp        = File.open(filename)
    dxf       = { 'HEADER' => {}, 'BLOCKS' => [], 'ENTITIES' => [] }

    #
    # main loop
    #

    loop do
      c, v = read_codes(fp)
      break if v == 'EOF'
      if v == 'SECTION'
        c, v = read_codes(fp)

        if v == 'HEADER'
          hdr = dxf['HEADER']
          loop do
            c, v = read_codes(fp)
            break if v == 'ENDSEC'
            if c == 9
              key = v
              hdr[key] = {}
            else
              add_att(hdr[key], c, v)
            end
          end
        end

        if v == 'BLOCKS'
          blks = dxf[v]
          parse_entities(blks, fp)
        end

        if v == 'ENTITIES'
          ents = dxf[v]
          parse_entities(ents, fp)
        end

      end
    end

    return dxf
  end

  def parse_entities(section, fp)
    last_ent = nil
    last_code = nil
    loop do
      c, v = read_codes(fp)
      break if v == 'ENDSEC'
      next if c == 999
      # LWPOLYLINE seems to break the rule that we can ignore the order of codes.
      if last_ent == 'LWPOLYLINE'
        if c == 10
          section[-1][42] ||= []
          # Create default 42
          add_att(section[-1], 42, 0.0)
        end
        if c == 42
          # update default
          section[-1][42][-1] = v
          next
        end
      end
      if c == 0
        last_ent = v
        section << { c => v }
      else
        add_att(section[-1], c, v)
      end
      last_code = c
    end
  end

  def read_codes(fp)
    c = fp.gets.to_i
    v = fp.gets.strip
    v.upcase! if c == 0
    case c
    when 10..59, 140..147, 210..239, 1010..1059
      v = v.to_f
    when 60..79, 90..99, 170..175, 280..289, 370..379, 380..389, 500..409, 1060..1079
      v = v.to_i
    end
    return([c, v])
  end

  def add_att(ent, code, value)
    # Initially, I thought each code mapped to a single value. Turns out
    # a code can be a list of values.
    if ent.nil? && $JFDEBUG
      p caller
      p code
      p value
    end
    if ent[code].nil?
      ent[code] = value
    elsif ent[code].class == Array
      ent[code] << value
    else
      t = ent[code]
      ent[code] = []
      ent[code] << t
      ent[code] << value
    end
  end
end

if $0 == __FILE__
  require 'pp'
  t1 = Time.now
  dxf = Dxf2Ruby.parse(ARGV.shift)
  puts "Finsihed in #{Time.now - t1}"
  dxf.keys.each do |section|
    dxf[section].each do |line|
      p line
    end
  end
end
