import os
import shutil
import defold_content_helpers
import blender_utils
import pygltflib

from pygltflib.utils import ImageFormat

# Generated output paths
MATERIAL_PATH     = "%s/materials"
MESH_PATH         = "%s/meshes"
TEXTURE_PATH      = "%s/textures"
MODEL_PATH        = "%s/models"
GAMEOBJECT_PATH   = "%s/gameobjects"
COLLECTION_PATH   = "%s/collections"

class projectcontext(object):
    def __init__(self, gltf_path, output_path):
        super(projectcontext, self).__init__()
        self.path_gltf   = gltf_path
        self.path_output = output_path
        self.buildpaths()

    def buildpaths(self):
        self.PROJECT_BASE_PATH = os.path.basename(self.path_output)

        self.MATERIAL_PATH   = "%s/materials" % self.path_output
        self.MESH_PATH       = "%s/meshes" % self.path_output
        self.TEXTURE_PATH    = "%s/textures" % self.path_output
        self.MODEL_PATH      = "%s/models" % self.path_output
        self.GAMEOBJECT_PATH = "%s/gameobjects" % self.path_output
        self.COLLECTION_PATH = "%s/collections" % self.path_output

        # Scene content paths
        self.TEXTURE_2D_BLANK_PATH   = "/defold-pbr/textures/blank_1x1.png"
        self.TEXTURE_CUBE_BLANK_PATH = "/defold-pbr/textures/blank_cube.cubemap"
        self.VERTEX_PATH             = "/defold-pbr/shaders/pbr.vp"
        self.FRAGMENT_PATH           = "/defold-pbr/shaders/pbr.fp"

    def get_texture(self, tex):
        if tex != None:
            return self.defold_texture_lut[tex.index]

    def write_material(self, material):
        data = material.serialize()
        path = "%s/%s.material" % (self.MATERIAL_PATH, material.name)
        with open(path, "w") as f:
            f.write(data)

    def write_model(self, model):
        data = model.serialize()
        path = "%s/%s.model" % (self.MODEL_PATH, model.name)
        with open(path, "w") as f:
            f.write(data)

    def write_gameobject(self, go):
        data = go.serialize()
        path = "%s/%s.go" % (self.GAMEOBJECT_PATH, go.name)
        with open(path, "w") as f:
            f.write(data)

    def write_collection(self, col):
        data = col.serialize()
        path = "%s/%s.collection" % (self.COLLECTION_PATH, col.name)
        with open(path, "w") as f:
            f.write(data)

    def write_collection_proxy(self, col_proxy):
        data = col_proxy.serialize()
        path = "%s/%s.collectionproxy" % (self.path_output, os.path.basename(self.path_gltf))
        with open(path, "w") as f:
            f.write(data)

    def build(self):
        print("Building %s to %s" % (self.path_gltf, self.path_output))
        gltf_file = pygltflib.GLTF2().load(self.path_gltf)

        for x in [self.MATERIAL_PATH, self.MESH_PATH, self.TEXTURE_PATH, self.MODEL_PATH, self.GAMEOBJECT_PATH, self.COLLECTION_PATH]:
            os.makedirs(x, exist_ok=True)


        convert_gltf_separate_files_path = os.path.join(os.path.dirname(__file__), "convert_gltf_separate_files.py")
        blender_utils.run_blender_script(convert_gltf_separate_files_path, [self.path_gltf, self.MESH_PATH])

        defold_collection = defold_content_helpers.collection("content")

        defold_collection_proxy = defold_content_helpers.collection_proxy("preview")
        defold_collection_proxy.set_collection("/%s/collections/content.collection" % self.PROJECT_BASE_PATH)

        self.defold_material_lut = {}
        self.defold_texture_lut = {}

        gltf_base_path = os.path.dirname(os.path.abspath(self.path_gltf))

        gltf_file.convert_images(ImageFormat.FILE, path=self.TEXTURE_PATH)
        for i in range(len(gltf_file.images)):
            if gltf_file.images[i].name == None:
                gltf_file.images[i].name = "Texture_%d" % i

            ext = "png"
            if gltf_file.images[i].mimeType != None and gltf_file.images[i].mimeType == "image/jpeg":
                ext = "jpg"

            self.defold_texture_lut[i] = gltf_file.images[i].name
            image_path_i     = "%s/%s" %  (self.TEXTURE_PATH, gltf_file.images[i].uri) # (gltf_base_path, gltf_file.images[i].uri) #(self.TEXTURE_PATH, i, ext)
            image_path_named = "%s/%s.png" % (self.TEXTURE_PATH, gltf_file.images[i].name)

            print(gltf_file.images[i])

            if gltf_file.images[i].uri == None:
                image_path_i = "%s/%s.%s" % (self.TEXTURE_PATH, i, ext)
                shutil.move(image_path_i, image_path_named)
            else:
                shutil.copy(image_path_i, image_path_named)

        for i in range(len(gltf_file.materials)):
            if gltf_file.materials[i].name == None:
                gltf_file.materials[i].name = "Material_%d" % i

            defold_material = defold_content_helpers.material(gltf_file.materials[i].name)

            defold_material.set_vertex_space(defold_content_helpers.VERTEX_SPACE_LOCAL)
            defold_material.set_vertex_program(self.VERTEX_PATH)
            defold_material.set_fragment_program(self.FRAGMENT_PATH)

            defold_material.add_tag("model")
            defold_material.add_sampler("tex_diffuse_irradiance")
            defold_material.add_sampler("tex_prefiltered_reflection", defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR)
            defold_material.add_sampler("tex_brdflut")
            defold_material.add_sampler("tex_albedo",             defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR, defold_content_helpers.FILTER_MODE_MAG_LINEAR, 16.0)
            defold_material.add_sampler("tex_metallic_roughness", defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR, defold_content_helpers.FILTER_MODE_MAG_LINEAR, 16.0)
            defold_material.add_sampler("tex_normal",             defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR, defold_content_helpers.FILTER_MODE_MAG_LINEAR, 16.0)
            defold_material.add_sampler("tex_occlusion",          defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR, defold_content_helpers.FILTER_MODE_MAG_LINEAR, 16.0)
            defold_material.add_sampler("tex_emissive",           defold_content_helpers.FILTER_MODE_MIN_LINEAR_MIPMAP_LINEAR, defold_content_helpers.FILTER_MODE_MAG_LINEAR, 16.0)

            """
            pbr_params = [
                baseColorFactor,
                [
                    metallicFactor,
                    roughnessFactor,
                    baseColorTexture != None and 1 or 0,
                    normalTexture != None and 1 or 0
                ],
                [
                    emissiveTexture != None and 1 or 0,
                    metallicRoughnessTexture != None and 1 or 0,
                    occlusionTexture != None and 1 or 0,
                    0
                ],
                [0,0,0,0]
            ]
            """

            #print(gltf_file.materials[i])

            texture_base_color         = self.get_texture(gltf_file.materials[i].pbrMetallicRoughness.baseColorTexture)
            texture_metallic_roughness = self.get_texture(gltf_file.materials[i].pbrMetallicRoughness.metallicRoughnessTexture)
            texture_normal             = self.get_texture(gltf_file.materials[i].normalTexture)
            texture_occlusion          = self.get_texture(gltf_file.materials[i].occlusionTexture)
            texture_emissive           = self.get_texture(gltf_file.materials[i].emissiveTexture)

            defold_material.add_texture(defold_content_helpers.TEXTURE_IRRADIANCE,           self.TEXTURE_CUBE_BLANK_PATH)
            defold_material.add_texture(defold_content_helpers.TEXTURE_PREFILTER_REFLECTION, self.TEXTURE_CUBE_BLANK_PATH)
            defold_material.add_texture(defold_content_helpers.TEXTURE_BRDF_LUT,             self.TEXTURE_2D_BLANK_PATH)
            defold_material.add_texture(defold_content_helpers.TEXTURE_BASE,                 texture_base_color)
            defold_material.add_texture(defold_content_helpers.TEXTURE_METALLIC_ROUGHNESS,   texture_metallic_roughness)
            defold_material.add_texture(defold_content_helpers.TEXTURE_NORMAL,               texture_normal)
            defold_material.add_texture(defold_content_helpers.TEXTURE_OCCLUSION,            texture_occlusion)
            defold_material.add_texture(defold_content_helpers.TEXTURE_EMISSIVE,             texture_emissive)

            defold_material.add_constant(defold_content_helpers.CONSTANT_VERTEX, defold_content_helpers.CONSTANT_TYPE_VIEW,       "u_mtx_view")
            defold_material.add_constant(defold_content_helpers.CONSTANT_VERTEX, defold_content_helpers.CONSTANT_TYPE_WORLD,      "u_mtx_world")
            defold_material.add_constant(defold_content_helpers.CONSTANT_VERTEX, defold_content_helpers.CONSTANT_TYPE_WORLDVIEW,  "u_mtx_worldview")
            defold_material.add_constant(defold_content_helpers.CONSTANT_VERTEX, defold_content_helpers.CONSTANT_TYPE_PROJECTION, "u_mtx_projection")
            defold_material.add_constant(defold_content_helpers.CONSTANT_VERTEX, defold_content_helpers.CONSTANT_TYPE_NORMAL,     "u_mtx_normal")

            pbr_params_0 = gltf_file.materials[i].pbrMetallicRoughness.baseColorFactor
            pbr_params_1 = [
                gltf_file.materials[i].pbrMetallicRoughness.metallicFactor,
                gltf_file.materials[i].pbrMetallicRoughness.roughnessFactor,
                texture_base_color != None and 1 or 0,
                texture_normal     != None and 1 or 0
            ]
            pbr_params_2 = [
                texture_emissive           != None and 1 or 0,
                texture_metallic_roughness != None and 1 or 0,
                texture_occlusion          != None and 1 or 0,
                0
            ]

            defold_material.add_constant(defold_content_helpers.CONSTANT_FRAGMENT, defold_content_helpers.CONSTANT_TYPE_VEC4, "u_pbr_params_0", pbr_params_0)
            defold_material.add_constant(defold_content_helpers.CONSTANT_FRAGMENT, defold_content_helpers.CONSTANT_TYPE_VEC4, "u_pbr_params_1", pbr_params_1)
            defold_material.add_constant(defold_content_helpers.CONSTANT_FRAGMENT, defold_content_helpers.CONSTANT_TYPE_VEC4, "u_pbr_params_2", pbr_params_2)

            self.write_material(defold_material)

            self.defold_material_lut[defold_material.name] = defold_material

        for i in range(len(gltf_file.nodes)):
            if gltf_file.nodes[i].mesh == None:
                continue

            if gltf_file.nodes[i].name == None:
                gltf_file.nodes[i].name = "Model_%d" % i

            mesh         = gltf_file.meshes[gltf_file.nodes[i].mesh]
            primitive    = mesh.primitives[0]
            material     = gltf_file.materials[primitive.material]

            mesh_path     = "/%s/meshes/%s.glb" % (self.PROJECT_BASE_PATH, gltf_file.nodes[i].name)
            material_path = "/%s/materials/%s.material" % (self.PROJECT_BASE_PATH, material.name)

            defold_model = defold_content_helpers.model(gltf_file.nodes[i].name)
            defold_model.set_mesh(mesh_path)
            defold_model.set_material(material_path)

            defold_material = self.defold_material_lut[material.name]
            for k,v in defold_material.textures.items():
                tex = self.TEXTURE_2D_BLANK_PATH
                if v != None:
                    if v.startswith("/defold-pbr"):
                        tex = v
                    else:
                        tex = "/%s/textures/%s.png" % (self.PROJECT_BASE_PATH, v)
                defold_model.add_texture(tex)
            self.write_model(defold_model)

            defold_go = defold_content_helpers.gameobject(gltf_file.nodes[i].name)
            defold_go.set_model("/%s/models/%s.model" % (self.PROJECT_BASE_PATH, gltf_file.nodes[i].name))
            self.write_gameobject(defold_go)

            defold_go_path = "/%s/gameobjects/%s.go" % (self.PROJECT_BASE_PATH, gltf_file.nodes[i].name)
            defold_collection.add_go(gltf_file.nodes[i].name, defold_go_path)

        self.write_collection(defold_collection)

        self.write_collection_proxy(defold_collection_proxy)

def do_build_project(args, output_path=None):
    for x in args:
        if output_path == None:
            output_path = os.path.splitext(os.path.abspath(x))[0] + "_Build"

        ctx = projectcontext(x, output_path)
        ctx.build()
