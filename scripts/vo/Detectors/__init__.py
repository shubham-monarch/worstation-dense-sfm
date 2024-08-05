from scripts.vo.Detectors.HandcraftDetector import HandcraftDetector
from scripts.vo.Detectors.SuperPointDetector import SuperPointDetector


def create_detector(conf):
    try:
        code_line = f"{conf['name']}(conf)"
        detector = eval(code_line)
    except NameError:
        raise NotImplementedError(f"{conf['name']} is not implemented yet.")

    return detector
