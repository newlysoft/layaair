package laya.d3.core.render {
	import laya.d3.core.Layer;
	import laya.d3.core.Sprite3D;
	import laya.d3.core.Transform3D;
	import laya.d3.core.material.Material;
	import laya.d3.graphics.RenderCullingObject;
	import laya.d3.math.BoundBox;
	import laya.d3.math.BoundSphere;
	import laya.d3.math.Vector3;
	import laya.events.Event;
	import laya.events.EventDispatcher;
	import laya.resource.IDispose;
	
	/**
	 * <code>Render</code> 类用于渲染器的父类，抽象类不允许示例。
	 */
	public class BaseRender extends EventDispatcher implements IDispose {
		/** @private */
		private var _owner:Sprite3D;
		/** @private */
		private var _enable:Boolean;
		/** @private */
		private var _renderCullingObject:RenderCullingObject;
		/** @private */
		private var _materials:Vector.<Material>;
		/** @private */
		protected var _boundingSphereNeedChange:Boolean;
		/** @private */
		protected var _boundingBoxNeedChange:Boolean;
		/** @private */
		protected var _boundingSphere:BoundSphere;
		/** @private */
		protected var _boundingBox:BoundBox;
		
		
		/**
		 * 获取是否可用。
		 * @return 是否可用。
		 */
		public function get enable():Boolean {
			return _enable;
		}
		
		/**
		 * 设置是否可用。
		 * @param value 是否可用。
		 */
		public function set enable(value:Boolean):void {
			_enable = value;
			event(Event.ENABLED_CHANGED, [this, value]);
		}
		
		/**
		 * 获取包围盒。
		 * @return 包围盒。
		 */
		public function get renderCullingObject():RenderCullingObject {
			return _renderCullingObject;
		}
		
		/**
		 * 返回第一个实例材质,第一次使用会拷贝实例对象。
		 * @return 第一个实例材质。
		 */
		public function get material():Material {
			var material:Material = _materials[0];
			if (material && !material._isInstance) {
				var instanceMaterial:Material = new Material();
				material.copy(instanceMaterial);//深拷贝
				instanceMaterial.name = instanceMaterial.name + "(Instance)";
				instanceMaterial._isInstance = true;
				_materials[0] = instanceMaterial;
				event(Event.MATERIAL_CHANGED, [this, [material], [instanceMaterial]]);
			}
			return _materials[0];
		}
		
		/**
		 * 设置第一个实例材质。
		 * @param value 第一个实例材质。
		 */
		public function set material(value:Material):void {
			var oldMaterial:Material = _materials[0];
			_materials[0] = value;
			event(Event.MATERIAL_CHANGED, [this, [oldMaterial], [value]]);
		}
		
		/**
		 * 获取潜拷贝实例材质列表,第一次使用会拷贝实例对象。
		 * @return 浅拷贝实例材质列表。
		 */
		public function get materials():Vector.<Material> {
			for (var i:int = 0, n:int = _materials.length; i < n; i++) {
				var material:Material = _materials[i];
				if (!material._isInstance) {
					var instanceMaterial:Material = new Material();
					material.copy(instanceMaterial);//深拷贝
					instanceMaterial.name = instanceMaterial.name + "(Instance)";
					instanceMaterial._isInstance = true;
					_materials[i] = instanceMaterial;
					event(Event.MATERIAL_CHANGED, [this, [material], [instanceMaterial]]);
				}
			}
			return _materials.slice();
		}
		
		/**
		 * 设置实例材质列表。
		 * @param value 实例材质列表。
		 */
		public function set materials(value:Vector.<Material>):void {
			if (!value)
				throw new Error("MeshRender: materials value can't be null.");
			
			var oldMaterials:Vector.<Material> = _materials;
			_materials = value;
			event(Event.MATERIAL_CHANGED, [this, oldMaterials.slice(), value.slice()]);
		}
		
		/**
		 * 返回第一个材质。
		 * @return 第一个材质。
		 */
		public function get shadredMaterial():Material {
			return _materials[0];
		}
		
		/**
		 * 设置第一个材质。
		 * @param value 第一个材质。
		 */
		public function set shadredMaterial(value:Material):void {
			var oldMaterial:Material = _materials[0];
			_materials[0] = value;
			event(Event.MATERIAL_CHANGED, [this, [oldMaterial], [value]]);
		}
		
		/**
		 * 获取浅拷贝材质列表。
		 * @return 浅拷贝材质列表。
		 */
		public function get shadredMaterials():Vector.<Material> {
			var materials:Vector.<Material> = _materials.slice();
			return materials;
		}
		
		/**
		 * 设置材质列表。
		 * @param value 材质列表。
		 */
		public function set shadredMaterials(value:Vector.<Material>):void {
			if (!value)
				throw new Error("MeshRender: shadredMaterials value can't be null.");
			
			var oldMaterials:Vector.<Material> = _materials;
			_materials = value;
			event(Event.MATERIAL_CHANGED, [this, oldMaterials.slice(), value.slice()]);
		}
		
		/**
		 * 获取包围球。
		 * @return 包围球。
		 */
		public function get boundingSphere():BoundSphere {
			if (_boundingSphereNeedChange) {
				_calculateBoundingSphere();
				_boundingSphereNeedChange = false;
			}
			return _boundingSphere;
		}
		
		/**
		 * 获取包围盒。
		 * @return 包围盒。
		 */
		public function get boundingBox():BoundBox {
			if (_boundingBoxNeedChange) {
				_calculateBoundingBox();
				_boundingBoxNeedChange = false;
			}
			return _boundingBox;
		}
		
		public function BaseRender(owner:Sprite3D) {
			_owner = owner;
			_enable = true;
			_boundingBox = new BoundBox(new Vector3(), new Vector3());
			_boundingSphere = new BoundSphere(new Vector3(), 0);
			_boundingSphereNeedChange = true;
			_boundingBoxNeedChange = true;
			_renderCullingObject = new RenderCullingObject();
			_renderCullingObject._render = this;
			_renderCullingObject._layerMask = _owner.layer.mask;
			_renderCullingObject._ownerEnable = _owner.enable;
			_renderCullingObject._enable = _enable;
			_materials = new Vector.<Material>();
			
			_owner.transform.on(Event.WORLDMATRIX_NEEDCHANGE, this, _onWorldMatNeedChange);
			_owner.on(Event.LAYER_CHANGED, this, _onOwnerLayerChanged);
			_owner.on(Event.ENABLED_CHANGED, this, _onOwnerEnableChanged);
			on(Event.ENABLED_CHANGED, this, _onEnableChanged);
		
		}
		
		/**
		 * @private
		 */
		private function _onWorldMatNeedChange():void {
			_boundingSphereNeedChange = true;
			_boundingBoxNeedChange = true;
		}
		
		/**
		 * @private
		 */
		private function _onOwnerLayerChanged(layer:Layer):void {
			_renderCullingObject._layerMask = layer.mask;
		}
		
		/**
		 * @private
		 */
		private function _onOwnerEnableChanged(enable:Boolean):void {
			_renderCullingObject._ownerEnable = enable;
		}
		
		/**
		 * @private
		 */
		private function _onEnableChanged(sender:BaseRender, enable:Boolean):void {
			_renderCullingObject._enable = enable;
		}
		
		/**
		 * @private
		 */
		protected function _calculateBoundingSphere():void {
			throw("BaseRender: must override it.");
		}
		
		/**
		 * @private
		 */
		protected function _calculateBoundingBox():void {
			throw("BaseRender: must override it.");
		}
		
		/**
		 * 彻底清理资源。
		 */
		public function dispose():void {
			_owner.transform.off(Event.WORLDMATRIX_NEEDCHANGE, this, _onWorldMatNeedChange);
			_owner.off(Event.LAYER_CHANGED, this, _onOwnerLayerChanged);
			_owner.off(Event.ENABLED_CHANGED, this, _onOwnerEnableChanged);
			off(Event.ENABLED_CHANGED, this, _onEnableChanged);
		}
	
	}

}