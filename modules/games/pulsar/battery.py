import glob
import os
import select

SIGNATURE = bytes.fromhex("0602ff0902a1018508")


def find_node():
    for path in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        with open(f"{path}/device/uevent") as f:
            if ":00003710:" not in f.read():
                continue
        with open(f"{path}/device/report_descriptor", "rb") as f:
            if SIGNATURE in f.read():
                return "/dev/" + os.path.basename(path)
    return None


def command(fd, cmd, arg=0):
    packet = bytearray(17)
    packet[0], packet[1], packet[6] = 8, cmd, arg
    packet[16] = (0x55 - sum(packet)) & 0xFF
    for _ in range(5):
        os.write(fd, packet)
        for _ in range(20):
            if not select.select([fd], [], [], 0.2)[0]:
                break
            reply = os.read(fd, 17)
            if reply[:3] == bytes(packet[:3]):
                return reply
    return None


def set_online(fd, state):
    for _ in range(50):
        reply = command(fd, 3, state)
        if reply is None or reply[10] != 1:
            return reply
    return None


def read_battery(fd):
    try:
        online = set_online(fd, 1)
        if online is None or online[6] != 1:
            return ""
        reply = command(fd, 4)
        return "" if reply is None else f"{reply[6]} {int(reply[7] == 1)}"
    finally:
        set_online(fd, 0)


def main():
    node = find_node()
    if node is None:
        return
    try:
        fd = os.open(node, os.O_RDWR)
        try:
            state = read_battery(fd)
        finally:
            os.close(fd)
        if state:
            print(state)
    except OSError:
        pass


main()
