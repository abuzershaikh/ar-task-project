import os
from PIL import Image, ImageDraw

def main():
    src_path = r"C:\Users\Abuzar\.gemini\antigravity-ide\brain\ff0568ad-fc87-461c-92b4-80a50ad16860\admin_app_icon_1788943812118.jpg"
    admin_res_dir = r"E:\pc2\android  project\Task  project\ar-task-project\Admin app\android\app\src\main\res"
    admin_assets_dir = r"E:\pc2\android  project\Task  project\ar-task-project\Admin app\assets\icons"

    os.makedirs(admin_assets_dir, exist_ok=True)

    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    # Also crop slightly (inset by ~4% if needed) to ensure the emblem fills the icon nicely
    # Let's inspect: 1024x1024 is already centered nicely
    master_icon = img.copy()

    # Save master assets
    master_icon.save(os.path.join(admin_assets_dir, "app_logo.png"), "PNG")
    master_icon.resize((512, 512), Image.LANCZOS).save(os.path.join(admin_assets_dir, "app_icon.png"), "PNG")
    print("Saved master icons in assets/icons")

    # Prepare circular mask for round icon
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((8, 8, w - 8, h - 8), fill=255)
    
    round_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    round_img.paste(img, (0, 0), mask=mask)

    # Densities map
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    for folder, size in densities.items():
        folder_path = os.path.join(admin_res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)

        # Standard icon
        sq_resized = img.resize((size, size), Image.LANCZOS)
        sq_path = os.path.join(folder_path, "ic_launcher.png")
        sq_resized.save(sq_path, "PNG")

        # Round icon
        round_resized = round_img.resize((size, size), Image.LANCZOS)
        round_path = os.path.join(folder_path, "ic_launcher_round.png")
        round_resized.save(round_path, "PNG")

        print(f"Generated {folder} ({size}x{size}): ic_launcher.png & ic_launcher_round.png")

    print("ALL ICONS GENERATED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
