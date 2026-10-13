---
name: blender-mcp
description: 透過與 blender-mcp 附加元件的 socket 連線，直接從 Hermes 控制 Blender。建立 3D 物件、材質、動畫，並執行任意的 Blender Python (bpy) 程式碼。當使用者想要在 Blender 中建立或修改任何內容時使用。
version: 1.0.0
requires: Blender 4.3+ (需要桌面執行個體，不支援無頭模式)
author: alireza78a
tags: [blender, 3d, animation, modeling, bpy, mcp]
---

# Blender MCP

透過 TCP 連接埠 9876 的 socket 從 Hermes 控制執行中的 Blender 執行個體。

## 設定 (一次性)

### 1. 安裝 Blender 附加元件

    curl -sL https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py -o ~/Desktop/blender_mcp_addon.py

在 Blender 中：
    Edit > Preferences > Add-ons > Install > 選擇 blender_mcp_addon.py
    啟用 "Interface: Blender MCP"

### 2. 在 Blender 中啟動 socket 伺服器

在 Blender 視埠中按下 N 開啟側邊欄。
找到 "BlenderMCP" 標籤並點擊 "Start Server"。

### 3. 驗證連線

    nc -z -w2 localhost 9876 && echo "OPEN" || echo "CLOSED"

## 協定

透過 TCP 傳輸純 UTF-8 JSON -- 無長度前綴。

傳送：     {"type": "<command>", "params": {<kwargs>}}
接收：     {"status": "success", "result": <value>}
          {"status": "error",   "message": "<reason>"}

## 可用指令

| type                    | params            | 說明                            |
|-------------------------|-------------------|---------------------------------|
| execute_code            | code (str)        | 執行任意 bpy Python 程式碼      |
| get_scene_info          | (none)            | 列出場景中的所有物件            |
| get_object_info         | object_name (str) | 特定物件的詳細資訊              |
| get_viewport_screenshot | (none)            | 當前視埠的螢幕截圖              |

## Python 輔助程式

在 execute_code 工具呼叫中使用：

    import socket, json

    def blender_exec(code: str, host="localhost", port=9876, timeout=15):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((host, port))
        s.settimeout(timeout)
        payload = json.dumps({"type": "execute_code", "params": {"code": code}})
        s.sendall(payload.encode("utf-8"))
        buf = b""
        while True:
            try:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
                try:
                    json.loads(buf.decode("utf-8"))
                    break
                except json.JSONDecodeError:
                    continue
            except socket.timeout:
                break
        s.close()
        return json.loads(buf.decode("utf-8"))

## 常見 bpy 模式

### 清除場景
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

### 新增網格物件
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(0, 0, 0))
    bpy.ops.mesh.primitive_cube_add(size=2, location=(3, 0, 0))
    bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=2, location=(-3, 0, 0))

### 建立並指派材質
    mat = bpy.data.materials.new(name="MyMat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (R, G, B, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.3
    bsdf.inputs["Metallic"].default_value = 0.0
    obj.data.materials.append(mat)

### 關鍵影格動畫
    obj.location = (0, 0, 0)
    obj.keyframe_insert(data_path="location", frame=1)
    obj.location = (0, 0, 3)
    obj.keyframe_insert(data_path="location", frame=60)

### 渲染至檔案
    bpy.context.scene.render.filepath = "/tmp/render.png"
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.ops.render.render(write_still=True)

## 注意事項

- 在執行前必須檢查 socket 是否開啟 (nc -z localhost 9876)
- 每次工作階段都必須在 Blender 內部啟動附加元件伺服器 (N 面板 > BlenderMCP > Connect)
- 將複雜場景拆分為多個較小的 execute_code 呼叫以避免逾時
- 渲染輸出路徑必須是絕對路徑 (/tmp/...) 而非相對路徑
- shade_smooth() 要求物件已被選取且處於物件模式 (object mode)
