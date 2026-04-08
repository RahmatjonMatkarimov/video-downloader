import asyncio
import logging
import os
import subprocess
import yt_dlp
import instaloader
from aiogram import Bot, Dispatcher, types, F
from aiogram.filters import Command
from aiogram.types import FSInputFile, InlineKeyboardMarkup, InlineKeyboardButton

# Telegram bot token
BOT_TOKEN = "8617618303:AAHJOrUSPANSM4hjjnWD5mk2j0w8IDjXRzI"

# Bot va dispatcher
bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()

# Logging
logging.basicConfig(level=logging.INFO)

# Downloads papkasi
DOWNLOAD_PATH = "downloads"
if not os.path.exists(DOWNLOAD_PATH):
    os.makedirs(DOWNLOAD_PATH)

async def delete_file_later(filepath: str, delay: int):
    """Faylni belgilangan vaqtdan keyin o'chiradi"""
    await asyncio.sleep(delay)
    if filepath and os.path.exists(filepath):
        try:
            os.remove(filepath)
        except Exception:
            pass

@dp.message(Command("start"))
async def start_handler(message: types.Message):
    await message.answer(
        "🚀 **Kuy Navo** (@video\\_yuklab\\_ber\\_bot)\n\n"
        "📥 Instagram’dan video, reel, story yoki highlight yuklab oling — *birgina link bilan!*\n\n"
        "🎵 Audio ajratib olish imkoniyati\n"
        "🚫 Hech qanday majburiy obuna va reklamasiz\n"
        "📱 Hech qanday qo'shimcha dastur kerak emas\n\n"
        "👇 Boshlash uchun Instagram havolasini yuboring!",
        parse_mode="Markdown"
    )

# Instagram link qabul qilish
@dp.message(F.text.regexp(r"(https?://)?(www\.)?instagram\.com/(p|reel|tv|stories|highlights)/([\w\-]+)/?"))
async def handle_instagram_link(message: types.Message):
    url = message.text
    msg = await message.answer(
        "⏳ **Yuklanmoqda...**\n\nIltimos, biroz kuting 🚀",
        parse_mode="Markdown"
    )

    try:
        # Shortcode ni olish
        import re
        match = re.search(r'instagram\.com/(p|reel|tv|stories|highlights)/([\w\-]+)', url)
        if not match:
            raise ValueError("Invalid URL")
        shortcode = match.group(2)

        # Instaloader bilan yuklash
        L = instaloader.Instaloader()
        L.dirname_pattern = DOWNLOAD_PATH
        post = instaloader.Post.from_shortcode(L.context, shortcode)
        L.download_post(post, target=DOWNLOAD_PATH)

        # Faylni topish
        input_file = None
        for file in os.listdir(DOWNLOAD_PATH):
            if file.startswith(shortcode) and (file.endswith('.mp4') or file.endswith('.jpg')):
                input_file = os.path.join(DOWNLOAD_PATH, file)
                break

        if input_file and os.path.exists(input_file):
            if input_file.endswith('.mp4'):
                keyboard = InlineKeyboardMarkup(inline_keyboard=[
                    [InlineKeyboardButton(text="🎵 Faqat audio yuklash", callback_data=f"audio_{shortcode}")]
                ])
                video_file = FSInputFile(input_file)
                await bot.send_video(
                    message.chat.id,
                    video_file,
                    caption="📥 **Video tayyor!**\n\n🎯 Yana yuklash uchun boshqa link yuboring.\n\n🤖 @video\\_yuklab\\_ber\\_bot",
                    reply_markup=keyboard,
                    parse_mode="Markdown"
                )
            else:
                # Agar rasm bo'lsa
                photo_file = FSInputFile(input_file)
                await bot.send_photo(
                    message.chat.id,
                    photo_file,
                    caption="📥 **Rasm tayyor!**\n\n🎯 Yana yuklash uchun boshqa link yuboring.\n\n🤖 @video\\_yuklab\\_ber\\_bot",
                    parse_mode="Markdown"
                )
            await msg.delete()

            # 10 daqiqadan keyin faylni o'chirish
            asyncio.create_task(delete_file_later(input_file, 600))
        else:
            await msg.edit_text(
                "❌ **Fayl topilmadi.**\n\n"
                "🔁 Iltimos, linkni tekshirib qayta yuboring.",
                parse_mode="Markdown"
            )

    except Exception as e:
        logging.error(f"Error downloading: {e}")
        await msg.edit_text(
            "❌ **Yuklab bo‘lmadi**\n\n"
            "🔁 Iltimos, linkni tekshirib qayta yuboring.\n"
            "📌 Faqat ochiq (public) postlar ishlaydi.",
            parse_mode="Markdown"
        )

# Audio tugmasi bosilganda
@dp.callback_query(F.data.startswith("audio_"))
async def process_audio(callback: types.CallbackQuery):
    video_id = callback.data.split("_")[1]
    input_file = None

    # Faylni topish
    for file in os.listdir(DOWNLOAD_PATH):
        if file.startswith(video_id) and not file.endswith(".mp3"):
            input_file = os.path.join(DOWNLOAD_PATH, file)
            break

    if not input_file:
        await callback.answer("Fayl topilmadi.", show_alert=True)
        return

    output_audio = os.path.join(DOWNLOAD_PATH, f"{video_id}.mp3")

    processing_msg = await bot.send_message(
        callback.message.chat.id,
        "🎵 **Audio ajratilmoqda...**\n\nBiroz kuting ⏳",
        parse_mode="Markdown"
    )

    try:
        # FFmpeg orqali audio ajratish
        subprocess.run([
            "ffmpeg", "-i", input_file, "-vn", "-acodec", "libmp3lame", "-q:a", "2", output_audio, "-y"
        ], check=True, capture_output=True)

        audio_file = FSInputFile(output_audio)
        await bot.send_audio(
            callback.message.chat.id,
            audio_file,
            caption="🎧 **Audio tayyor!**\n\n🔥 Yana yuklash uchun link yuboring.\n\n🤖 @video\\_yuklab\\_ber\\_bot",
            parse_mode="Markdown"
        )
        await processing_msg.delete()

        # Fayllarni o'chirish
        if os.path.exists(output_audio):
            os.remove(output_audio)
        if input_file and os.path.exists(input_file):
            os.remove(input_file)

    except Exception as e:
        logging.error(f"Error extracting audio: {e}")
        await processing_msg.edit_text(
            "❌ **Audio ajratib bo‘lmadi**\n\n🔁 Qayta urinib ko‘ring.",
            parse_mode="Markdown"
        )

# Botni ishga tushirish
async def main():
    print("🤖 Bot ishga tushdi!")
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())