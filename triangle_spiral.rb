import pya
#fix to match python ver.

module MyLib

  include RBA

  # Remove any definition of our classes (this helps when 
  # reexecuting this code after a change has been applied)
  MyLib.constants.member?(:Triangle) && remove_const(:Triangle)
  MyLib.constants.member?(:MyLib) && remove_const(:MyLib)
  
  # The PCell declaration for the triangle
  class Triangle < PCellDeclarationHelper
  
    include RBA

    def initialize

      # Important: initialize the super class
      super

      # declare the parameters
      param(:l, TypeLayer, "Layer", :default => LayerInfo::new(1, 0))
      param(:n, TypeInt, "Number of points", :default => 64)     
      param(:side_handle, TypeShape, "", :default => DPoint::new(0, 0))
      param(:side, TypeDouble, "Side-Length", :default => 0.1)
      # this hidden parameter is used to determine whether the radius has changed
      # or the "side" handle has been moved
      param(:side_mem, TypeDouble, "Side-Length Memory", :default => 0.0, :hidden => true)

    end
  
    def display_text_impl
      # Provide a descriptive text for the cell
      "Triangle(L=#{l.to_s},Side=#{'%.3f' % side.to_f})"
    end
    
    def coerce_parameters_impl
    
      # We employ coerce_parameters_impl to decide whether the handle or the 
      # numeric parameter has changed (by comparing against the effective 
      # radius ru) and set ru to the effective radius. We also update the 
      # numerical value or the shape, depending on which on has not changed.
      side_handle_l = nil
      if s.is_a?(DPoint) 
        # compute distance in micron
        rs = s.distance(DPoint::new(0, 0))
      end 
      if rs && (r-ru).abs < 1e-6
        set_ru rs
        set_r rs 
      else
        set_ru r 
        set_s DPoint::new(-r, 0)
      end
      
      # n must be larger or equal than 4
      n > 4 || (set_n 4)
       
    end
    
    def can_create_from_shape_impl
      # Implement the "Create PCell from shape" protocol: we can use any shape which 
      # has a finite bounding box
      shape.is_box? || shape.is_polygon? || shape.is_path?
    end
    
    def parameters_from_shape_impl
      # Implement the "Create PCell from shape" protocol: we set r and l from the shape's 
      # bounding box width and layer
      set_r shape.bbox.width * layout.dbu / 2
      set_l layout.get_info(layer)
    end
    
    def transformation_from_shape_impl
      # Implement the "Create PCell from shape" protocol: we use the center of the shape's
      # bounding box to determine the transformation
      Trans.new(shape.bbox.center)
    end
    
    def produce_impl
    
      # This is the main part of the implementation: create the layout

      # fetch the parameters
      ru_dbu = ru / layout.dbu
      
      # compute the circle
      pts = []
      da = Math::PI * 2 / n
      n.times do |i|
        pts.push(Point.from_dpoint(DPoint.new(ru_dbu * Math::cos(i * da), ru_dbu * Math::sin(i * da))))
      end
      
      # create the shape
      cell.shapes(l_layer).insert(Polygon.new(pts))
      
    end
  
  end
  
  # The library where we will put the PCell into 
  class MyLib < Library
  
    def initialize  
    
      # Set the description
      self.description = "My First Library"
      
      # Create the PCell declarations
      layout.register_pcell("Circle", Circle::new)
      # That would be the place to put in more PCells ...
      
      # Register us with the name "MyLib".
      # If a library with that name already existed, it will be replaced then.
      register("MyLib")
      
    end
  
  end
  
  # Instantiate and register the library
  MyLib::new
  
end

