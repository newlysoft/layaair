var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var MousePickingScene = (function (_super) {
    __extends(MousePickingScene, _super);
    function MousePickingScene() {
        _super.call(this);
        this.meshCount = 0;
        this.vertices = [];
        this.indexs = [];
        this.worldMats = [];
        this.vertex1 = new Laya.Vector3();
        this.vertex2 = new Laya.Vector3();
        this.vertex3 = new Laya.Vector3();
        this.closeVertex1 = new Laya.Vector3();
        this.closeVertex2 = new Laya.Vector3();
        this.closeVertex3 = new Laya.Vector3();
        this.point = new Laya.Vector2();
        this.ray = new Laya.Ray(new Laya.Vector3(), new Laya.Vector3());
        this.phasorSpriter3D = new Laya.PhasorSpriter3D();
        this.currentCamera = (this.addChild(new Laya.Camera(0, 0.1, 100)));
        this.currentCamera.transform.translate(new Laya.Vector3(0, 0.8, 1.5));
        this.currentCamera.transform.rotate(new Laya.Vector3(-30, 0, 0), true, false);
        var sprite3d = this.addChild(new Laya.Sprite3D());
        sprite3d.once(Laya.Event.HIERARCHY_LOADED, this, function (spirit3D) {
            this.getMeshData(spirit3D);
        });
        sprite3d.loadHierarchy("../../res/threeDimen/staticModel/simpleScene/B00IT001M000.v3f.lh");
        sprite3d.transform.localScale = new Laya.Vector3(10, 10, 10);
    }
    MousePickingScene.prototype.getMeshData = function (spirit3D) {
        if (spirit3D instanceof Laya.MeshSprite3D) {
            var meshSprite3D = spirit3D;
            var mesh = meshSprite3D.meshFilter.sharedMesh;
            if (mesh != null) {
                mesh.once(Laya.Event.LOADED, this, function () {
                    this.meshLoaded(mesh);
                    for (var i = 0; i < mesh.materials.length; i++)
                        mesh.materials[i].albedo = new Laya.Vector4(3.0, 3.0, 3.0, 1.0);
                });
                this.worldMats.push(meshSprite3D.transform.worldMatrix);
            }
        }
        for (var i = 0; i < spirit3D.numChildren; i++)
            this.getMeshData(spirit3D.getChildAt(i));
    };
    MousePickingScene.prototype.meshLoaded = function (mesh) {
        var submesheCount = mesh.getSubMeshCount();
        var worldMat = this.worldMats[this.meshCount];
        var positions = mesh.positions;
        for (var i = 0; i < submesheCount; i++) {
            var subMesh = mesh.getSubMesh(i);
            var vertexBuffer = subMesh.getVertexBuffer();
            var verts = vertexBuffer.getData();
            var subMeshVertices = [];
            for (var j = 0; j < verts.length; j += vertexBuffer.vertexDeclaration.vertexStride / 4) {
                var position = new Laya.Vector3(verts[j + 0], verts[j + 1], verts[j + 2]);
                Laya.Vector3.transformCoordinate(position, worldMat, position);
                subMeshVertices.push(position);
            }
            this.vertices.push(subMeshVertices);
            var ib = subMesh.getIndexBuffer();
            this.indexs.push(ib.getData());
        }
        this.meshCount++;
    };
    MousePickingScene.prototype.lateRender = function (state) {
        _super.prototype.lateRender.call(this, state);
        var camera = this.currentCamera;
        var projViewMat = camera.projectionViewMatrix;
        this.point.elements[0] = Laya.stage.mouseX;
        this.point.elements[1] = Laya.stage.mouseY;
        camera.viewportPointToRay(this.point, this.ray);
        var closestIntersection = Number.MAX_VALUE;
        for (var i = 0; i < this.vertices.length; i++) {
            var intersection = Laya.Picker.rayIntersectsPositionsAndIndices(this.ray, this.vertices[i], this.indexs[i], this.vertex1, this.vertex2, this.vertex3);
            if (!isNaN(intersection) && intersection < closestIntersection) {
                closestIntersection = intersection;
                this.vertex1.cloneTo(this.closeVertex1);
                this.vertex2.cloneTo(this.closeVertex2);
                this.vertex3.cloneTo(this.closeVertex3);
            }
        }
        this.phasorSpriter3D.begin(0x0001 /*Laya.WebGLContext.LINES*/, projViewMat, state);
        var original = this.ray.origin;
        this.phasorSpriter3D.line(original.x, original.y, original.z, 1.0, 0.0, 0.0, 1.0, 0, 0, 0, 1.0, 0.0, 0.0, 1.0);
        this.phasorSpriter3D.line(this.closeVertex1.elements[0], this.closeVertex1.elements[1], this.closeVertex1.elements[2], 1.0, 0.0, 0.0, 1.0, this.closeVertex2.elements[0], this.closeVertex2.elements[1], this.closeVertex2.elements[2], 1.0, 0.0, 0.0, 1.0);
        this.phasorSpriter3D.line(this.closeVertex2.elements[0], this.closeVertex2.elements[1], this.closeVertex2.elements[2], 1.0, 0.0, 0.0, 1.0, this.closeVertex3.elements[0], this.closeVertex3.elements[1], this.closeVertex3.elements[2], 1.0, 0.0, 0.0, 1.0);
        this.phasorSpriter3D.line(this.closeVertex3.elements[0], this.closeVertex3.elements[1], this.closeVertex3.elements[2], 1.0, 0.0, 0.0, 1.0, this.closeVertex1.elements[0], this.closeVertex1.elements[1], this.closeVertex1.elements[2], 1.0, 0.0, 0.0, 1.0);
        this.phasorSpriter3D.end();
    };
    return MousePickingScene;
}(Laya.Scene));
