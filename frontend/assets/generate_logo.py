import os
from PIL import Image, ImageDraw

def generate_logo():
    # We render at 4x resolution (4096 x 4096) for crisp antialiasing, then downscale to 1024 x 1024.
    scale = 4
    base_size = 1024
    render_size = base_size * scale
    
    # 1. Create a background with the primary brand color (#6366F1)
    # RGB for #6366F1 is (99, 102, 241)
    brand_color = (99, 102, 241)
    img = Image.new("RGB", (render_size, render_size), brand_color)
    draw = ImageDraw.Draw(img)
    
    # Coordinates scaled
    def s(val):
        return val * scale
        
    # Helper to calculate quadratic bezier curve
    def get_bezier_points(p0, p1, p2, num_steps=40):
        points = []
        for i in range(num_steps + 1):
            t = i / num_steps
            x = (1 - t)**2 * p0[0] + 2 * (1 - t) * t * p1[0] + t**2 * p2[0]
            y = (1 - t)**2 * p0[1] + 2 * (1 - t) * t * p1[1] + t**2 * p2[1]
            points.append((x, y))
        return points

    # Drawing the white graduation cap in the center.
    # Center X = 512, Center Y = 512 (base coordinates)
    # 1. Rhombus (Mortarboard top)
    rhombus_points = [
        (s(512), s(290)),   # Top
        (s(870), s(430)),   # Right
        (s(512), s(570)),   # Bottom
        (s(154), s(430))    # Left
    ]
    draw.polygon(rhombus_points, fill="white")
    
    # 2. Cap/skull shape below
    p_left = (s(320), s(485))
    p_left_ctrl = (s(320), s(610))
    p_bottom = (s(512), s(690))
    p_right_ctrl = (s(704), s(610))
    p_right = (s(704), s(485))
    
    curve1 = get_bezier_points(p_left, p_left_ctrl, p_bottom)
    curve2 = get_bezier_points(p_bottom, p_right_ctrl, p_right)
    
    cap_points = curve1 + curve2 + [(s(512), s(570)), p_left]
    draw.polygon(cap_points, fill="white")
    
    # 3. Center button
    btn_r = s(16)
    draw.ellipse(
        [s(512) - btn_r, s(430) - btn_r, s(512) + btn_r, s(430) + btn_r],
        fill="white"
    )
    
    # 4. Tassel band and hanging tassel
    tassel_band = get_bezier_points((s(512), s(430)), (s(650), s(450)), (s(760), s(510)))
    draw.line(tassel_band, fill="white", width=s(10))
    
    # Draw vertical tassel hanging line
    draw.line([(s(760), s(510)), (s(760), s(680))], fill="white", width=s(10))
    
    # Draw tassel brush (capsule-like shape at the bottom)
    brush_rect = [s(760) - s(18), s(680), s(760) + s(18), s(770)]
    draw.rounded_rectangle(brush_rect, radius=s(10), fill="white")
    
    # Resize to 1024 x 1024 with high quality resampling (LANCZOS)
    img_final = img.resize((base_size, base_size), Image.Resampling.LANCZOS)
    
    # Make sure output directory exists
    os.makedirs("assets", exist_ok=True)
    
    # Save the output image
    img_final.save("assets/logo.png", "PNG")
    print("Logo generated successfully at 'assets/logo.png'")

if __name__ == "__main__":
    generate_logo()
