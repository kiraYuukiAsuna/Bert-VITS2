# 字母到中文发音的映射
letter_to_pinyin = {
    'A': '诶', 'a': '诶',
    'B': '比', 'b': '比',
    'C': '西', 'c': '西',
    'D': '迪', 'd': '迪',
    'E': '伊', 'e': '伊',
    'F': '艾弗', 'f': '艾弗',
    'G': '吉', 'g': '吉',
    'H': '艾尺', 'h': '艾尺',
    'I': '艾', 'i': '艾',
    'J': '杰', 'j': '杰',
    'K': '开', 'k': '开',
    'L': '艾勒', 'l': '艾勒',
    'M': '艾姆', 'm': '艾姆',
    'N': '恩', 'n': '恩',
    'O': '哦', 'o': '哦',
    'P': '屁', 'p': '屁',
    'Q': '苦', 'q': '苦',
    'R': '艾儿', 'r': '艾儿',
    'S': '艾斯', 's': '艾斯',
    'T': '提', 't': '提',
    'U': '优', 'u': '优',
    'V': '维', 'v': '维',
    'W': '达布勒', 'w': '达布勒',
    'X': '艾克斯', 'x': '艾克斯',
    'Y': '歪', 'y': '歪',
    'Z': '贼', 'z': '贼'
}


def convert_to_pinyin(text):
    result = []
    for char in text:
        if char in letter_to_pinyin:
            result.append(letter_to_pinyin[char])
        else:
            result.append(char)
    return ''.join(result)


if __name__ == '__main__':
    # 输入示例
    input_text = "Hello World!"
    output_text = convert_to_pinyin(input_text)
    print(output_text)
