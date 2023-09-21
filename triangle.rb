import pya
import math


class Triangle(pya.PCellDeclarationHelper):
  """
  The PCell declaration for the triangle
  """

  def __init__(self):

    # Important: initialize the super class
    super(Triangle, self).__init__()

    # declare the parameters
    self.param("l", self.TypeLayer, "Layer", default = pya.LayerInfo(1, 0))
    self.param("n", self.TypeInt, "Number of points", default = 64) 
    self.param("side_handle", self.TypeShape, "", default = pya.DPoint(0, 0))
    self.param("side", self.TypeDouble, "Side Length", default = 50)
        
    # this hidden parameter is used to determine whether the radius has changed
    # or the "s" handle has been moved
    self.param("side_mem", self.TypeDouble, "Side Length Memory", default = 0.0, hidden = True)

  def display_text_impl(self):
    # Provide a descriptive text for the cell
    return "Triangle(L=" + str(self.l) + ",Side=" + ('%.3f' % self.side) + ")"
  
  def coerce_parameters_impl(self):
  
    # We employ coerce_parameters_impl to decide whether the handle or the 
    # numeric parameter has changed (by comparing against the effective 
    # radius ru) and set ru to the effective radius. We also update the 
    # numerical value or the shape, depending on which on has not changed.
    side_handle_l = None
    if isinstance(self.side_handle, pya.DPoint): 
      # compute distance in micron
      side_handle_l = self.side_handle.distance(pya.DPoint(0, 0))
    if abs(self.side-self.side_mem) < 1e-6:
      self.side_mem = side_handle_l
      self.side = side_handle_l 
    else:
      self.side_mem = self.side
      self.side_handle = pya.DPoint(-self.side, 0)
    
    
    # n must be larger or equal than 4
    if self.n <= 4:
      self.n = 4
  
  def can_create_from_shape_impl(self):
    # Implement the "Create PCell from shape" protocol: we can use any shape which 
    # has a finite bounding box
    return self.shape.is_box() or self.shape.is_polygon() or self.shape.is_path()
  
  def parameters_from_shape_impl(self):
    # Implement the "Create PCell from shape" protocol: we set r and l from the shape's 
    # bounding box width and layer
    self.side = self.shape.bbox().width() * self.layout.dbu / 2
    self.l = self.layout.get_info(self.layer)
  
  def transformation_from_shape_impl(self):
    # Implement the "Create PCell from shape" protocol: we use the center of the shape's
    # bounding box to determine the transformation
    return pya.Trans(self.shape.bbox().center())
  
  def produce_impl(self):
  
    # This is the main part of the implementation: create the layout

    # fetch the parameters
    side_dbu = self.side / self.layout.dbu
    
    # compute the triangle
    pts = [pya.Point.from_dpoint(pya.DPoint(0,0)),pya.Point.from_dpoint(pya.DPoint(0,side_dbu)),pya.Point.from_dpoint(pya.DPoint(side_dbu/2,(side_dbu/2)*math.sqrt(3)))]
    
    # create the shape
    self.cell.shapes(self.l_layer).insert(pya.Polygon(pts))


class MyLib(pya.Library):
  """
  The library where we will put the PCell into 
  """

  def __init__(self):
  
    # Set the description
    self.description = "My First Library"
    
    # Create the PCell declarations
    self.layout().register_pcell("Triangle", Triangle())
    # That would be the place to put in more PCells ...
    
    # Register us with the name "MyLib".
    # If a library with that name already existed, it will be replaced then.
    self.register("MyLib")


# Instantiate and register the library
MyLib()

