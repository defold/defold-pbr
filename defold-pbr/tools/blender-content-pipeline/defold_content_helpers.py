import inspect

## Constants
CONSTANT_VERTEX   = 0
CONSTANT_FRAGMENT = 1

TEXTURE_IRRADIANCE           = 0
TEXTURE_PREFILTER_REFLECTION = 1
TEXTURE_BRDF_LUT             = 2
TEXTURE_BASE                 = 3
TEXTURE_METALLIC_ROUGHNESS   = 4
TEXTURE_NORMAL               = 5
TEXTURE_OCCLUSION            = 6
TEXTURE_EMISSIVE             = 7

## Constant types
CONSTANT_TYPE_VEC4       = "CONSTANT_TYPE_USER"
CONSTANT_TYPE_MAT4       = "CONSTANT_TYPE_USER_MATRIX4"
CONSTANT_TYPE_WORLDVIEW  = "CONSTANT_TYPE_WORLDVIEW"
CONSTANT_TYPE_WORLD      = "CONSTANT_TYPE_WORLD"
CONSTANT_TYPE_VIEW       = "CONSTANT_TYPE_VIEW"
CONSTANT_TYPE_PROJECTION = "CONSTANT_TYPE_PROJECTION"
CONSTANT_TYPE_NORMAL     = "CONSTANT_TYPE_NORMAL"

VERTEX_SPACE_WORLD       = "VERTEX_SPACE_WORLD"
VERTEX_SPACE_LOCAL       = "VERTEX_SPACE_LOCAL"

FILTER_MODE_MIN_LINEAR               = "FILTER_MODE_MIN_LINEAR"
FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR = "FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR"
FILTER_MODE_MAG_LINEAR               = "FILTER_MODE_MAG_LINEAR"

def serialize_escaped_str(lbl, str):
    return "%s: \"%s\"" % (lbl, str)

def serialize_sampler(sampler, min_filter, mag_filter, max_anisotropy):
    SAMPLER_TEMPLATE = inspect.cleandoc("""
            samplers {{
                name: \"{name}\"
                wrap_u: WRAP_MODE_REPEAT
                wrap_v: WRAP_MODE_REPEAT
                filter_min: {min_filter}
                filter_mag: {mag_filter}
                max_anisotropy: {max_anisotropy}
            }}
            """)
    return SAMPLER_TEMPLATE.format(
        name           = sampler,
        min_filter     = min_filter,
        mag_filter     = mag_filter,
        max_anisotropy = max_anisotropy)

def serialize_vec3(lbl, value):
    VEC3_VALUE_TEMPLATE = inspect.cleandoc("""
        {label}: {{
            x: {x}
            y: {y}
            z: {z}
        }}
        """)
    return VEC3_VALUE_TEMPLATE.format(
        label = lbl,
        x = value[0],
        y = value[1],
        z = value[2])

def serialize_vec4(lbl, value):
    VEC4_VALUE_TEMPLATE = inspect.cleandoc("""
        {label}: {{
            x: {x}
            y: {y}
            z: {z}
            w: {w}
        }}
        """)
    return VEC4_VALUE_TEMPLATE.format(
        label = lbl,
        x = value[0],
        y = value[1],
        z = value[2],
        w = value[3])

def serialize_constant(sh_type, c_entry):
    sh_type_str = ""
    if sh_type == CONSTANT_VERTEX:
        sh_type_str = "vertex_constants"
    elif sh_type == CONSTANT_FRAGMENT:
        sh_type_str = "fragment_constants"

    CONSTANT_TEMPLATE = inspect.cleandoc("""
        {shader} {{
            name: \"{name}\"
            type: {type}
            {value}
        }}
        """)

    val = ""
    if c_entry["value"] != None:
        if c_entry["type"] == CONSTANT_TYPE_MAT4:
            for v in c_entry["value"]:
                val += serialize_vec4("value", v)
        if c_entry["type"] == CONSTANT_TYPE_VEC4:
            val += serialize_vec4("value", c_entry["value"])

    return CONSTANT_TEMPLATE.format(
        shader = sh_type_str,
        name   = c_entry["name"],
        type   = c_entry["type"],
        value  = val)

class material(object):
    def __init__(self, name):
        self.name               = name
        self.vertex_space       = ""
        self.vertex_program     = ""
        self.vertex_constants   = []
        self.fragment_program   = ""
        self.fragment_constants = []
        self.samplers           = []
        self.tags               = []
        self.textures           = {}

    def set_vertex_space(self, space):
        self.vertex_space = space

    def set_vertex_program(self, path):
        self.vertex_program = path

    def set_fragment_program(self, path):
        self.fragment_program = path

    def add_sampler(self, sampler_name, min_filter=FILTER_MODE_MIN_LINEAR, mag_filter=FILTER_MODE_MAG_LINEAR, max_anisotropy=1.0):
        self.samplers.append({
            "name"           : sampler_name,
            "min_filter"     : min_filter,
            "mag_filter"     : mag_filter,
            "max_anisotropy" : max_anisotropy})

    def add_tag(self, tag):
        self.tags.append(tag)

    def add_texture(self, t_type, t_name):
        self.textures[t_type] = t_name

    def add_constant(self, sh_type, c_type, c_name, c_value = None):
        constants = None
        if sh_type == CONSTANT_VERTEX:
            constants = self.vertex_constants
        elif sh_type == CONSTANT_FRAGMENT:
            constants = self.fragment_constants
        constants.append({
            "name"  : c_name,
            "type"  : c_type,
            "value" : c_value
        })

    def serialize(self):
        print("Serializing " + self.name)

        output_template = inspect.cleandoc(
            """
            {name}
            {tags}
            {vertex_program}
            {fragment_program}
            {vertex_space}
            {vertex_constants}
            {fragment_constants}
            {samplers}
            """)

        mat_name        = "name: \"%s\"" % self.name
        fs_program_path = "fragment_program: \"%s\"" % self.fragment_program
        vx_program_path = "vertex_program: \"%s\"" % self.vertex_program
        vx_space        = "vertex_space: %s" % self.vertex_space

        samplers_str = ""
        for x in self.samplers:
            samplers_str += serialize_sampler(x["name"], x["min_filter"], x["mag_filter"], x["max_anisotropy"]) + "\n"

        vx_constants_str = ""
        for x in self.vertex_constants:
            vx_constants_str += serialize_constant(CONSTANT_VERTEX, x) + "\n"

        fs_constants_str = ""
        for x in self.fragment_constants:
            fs_constants_str += serialize_constant(CONSTANT_FRAGMENT, x) + "\n"

        tags_str = ""
        for x in self.tags:
            tags_str += serialize_escaped_str("tags", x)

        return output_template.format(
            name               = mat_name,
            tags               = tags_str,
            vertex_program     = vx_program_path,
            fragment_program   = fs_program_path,
            vertex_space       = vx_space,
            vertex_constants   = vx_constants_str,
            fragment_constants = fs_constants_str,
            samplers           = samplers_str)

"""
mesh: "/main/preview.glb"
material: "/main/preview.material"
textures: "/assets/images/green.png"
skeleton: ""
animations: ""
default_animation: ""
name: "unnamed"
"""

class model(object):
    def __init__(self, name):
        self.name     = name
        self.mesh     = None
        self.material = None
        self.textures = []

    def set_mesh(self, mesh):
        self.mesh = mesh
    def set_material(self, material):
        self.material = material
    def add_texture(self, texture):
        self.textures.append(texture)

    def serialize(self):
        print("Serializing model " + self.name)

        output_template = inspect.cleandoc(
            """
            {mesh}
            {material}
            {textures}
            {skeleton}
            {animations}
            {default_animation}
            {name}
            """)

        t_str = ""
        for x in self.textures:
            t_str += serialize_escaped_str("textures", x) + "\n"

        return output_template.format(
            mesh              = serialize_escaped_str("mesh", self.mesh),
            material          = serialize_escaped_str("material", self.material),
            textures          = t_str,
            skeleton          = serialize_escaped_str("skeleton", ""),
            animations        = serialize_escaped_str("animations", ""),
            default_animation = serialize_escaped_str("default_animation", ""),
            name              = serialize_escaped_str("name", self.name)
            )

"""
components {
  id: "polySurface37.001"
  component: "/main/models/polySurface37.001.model"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
"""

class gameobject(object):
    def __init__(self, name):
        self.name = name
        self.position = [0,0,0]
        self.rotation = [0,0,0,1]
        self.model = None

    def set_model(self, model):
        self.model = model

    def serialize(self):
        print("Serializing gameobject " + self.name)

        output_template = inspect.cleandoc(
            """
            components {{
            {id}
            {component}
            {position}
            {rotation}
            }}
            """)

        return output_template.format(
            id        = serialize_escaped_str("id", self.name),
            component = serialize_escaped_str("component", self.model),
            position  = serialize_vec3("position", self.position),
            rotation  = serialize_vec4("rotation", self.rotation))

"""
name: "default"
instances {
  id: "polySurface37.001"
  prototype: "/main/gameobjects/polySurface37.001.go"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  scale3 {
    x: 1.0
    y: 1.0
    z: 1.0
  }
}
scale_along_z: 0
"""

def serialize_instance(id, path):
    INSTANCE_TEMPLATE = inspect.cleandoc("""
        instances: {{
            {id}
            {prototype}
        }}
        """)
    return INSTANCE_TEMPLATE.format(
        id = serialize_escaped_str("id", id),
        prototype = serialize_escaped_str("prototype", path))

class collection(object):
    def __init__(self, name):
        self.name = name
        self.instances = {}
    def add_go(self, id, path):
        self.instances[id] = path
    def serialize(self):
        print("Serializing collection " + self.name)

        output_template = inspect.cleandoc(
            """
            {name}
            {instances}
            """)

        i_str = ""
        for k,v in self.instances.items():
            i_str += serialize_instance(k, v) + "\n"

        return output_template.format(
            name = serialize_escaped_str("name", self.name),
            instances = i_str)

"""
collection: "/main/dummy/dummy.collection"
exclude: false
"""

class collection_proxy(object):
    def __init__(self, name):
        self.name = name
        self.collection = None
    def set_collection(self, coll):
        self.collection = coll
    def serialize(self):
        print("Serializing collection proxy " + self.name)

        output_template = inspect.cleandoc(
            """
            {collection}
            exclude: false
            """)
        return output_template.format(
            collection = serialize_escaped_str("collection", self.collection))
