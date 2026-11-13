// The senders' pictures of the Columns list: drawn by the core once for a key and size (a brand's logo, later a
// contact's picture) and kept as bitmaps for the run, so fifty rows of one sender cost one picture; while there is none
// a row shows its initials (columnrow.cpp).
#include "app.h"

namespace {

// how many pictures are kept; past it the ones used longest ago go
constexpr size_t kKept = 256;

}  // namespace


ListPictures::~ListPictures() {
    Clear();
}

void ListPictures::Clear() {
    for (auto& [at, picture] : pictures_) {
        if (picture.bitmap) {
            DeleteObject(picture.bitmap);
        }
    }
    pictures_.clear();
    requests_.clear();
}

HBITMAP ListPictures::Get(uint64_t key, int size) {
    if (!core_ || key == 0) {
        return nullptr;
    }
    std::pair<uint64_t, int> at = {key, size};
    auto found = pictures_.find(at);
    if (found != pictures_.end()) {
        found->second.used = ++clock_;
        return found->second.bitmap;
    }
    Trim();
    Picture& picture = pictures_[at];
    picture.used = ++clock_;
    // asked once; a key the core names no picture for stays without one
    if (uint64_t request = pe_picture_start(core_, key, static_cast<uint32_t>(size))) {
        requests_[request] = at;
        picture.pending = true;
    }
    return nullptr;
}

uint64_t ListPictures::Ready(uint64_t request) {
    auto found = requests_.find(request);
    if (found == requests_.end()) {
        return 0;
    }
    std::pair<uint64_t, int> at = found->second;
    requests_.erase(found);
    size_t length = 0;
    uint8_t* pixels = pe_picture_result(core_, request, &length);
    HBITMAP bitmap = CoreBitmap(pixels, length, at.second);
    auto picture = pictures_.find(at);
    if (picture == pictures_.end()) {
        // let go of meanwhile
        if (bitmap) {
            DeleteObject(bitmap);
        }
        return 0;
    }
    picture->second.bitmap = bitmap;
    picture->second.pending = false;
    return bitmap ? at.first : 0;
}

// room for one more: the picture used longest ago goes, unless the core is still drawing it
void ListPictures::Trim() {
    while (pictures_.size() >= kKept) {
        auto oldest = pictures_.end();
        for (auto it = pictures_.begin(); it != pictures_.end(); ++it) {
            if (!it->second.pending && (oldest == pictures_.end() || it->second.used < oldest->second.used)) {
                oldest = it;
            }
        }
        if (oldest == pictures_.end()) {
            return;
        }
        if (oldest->second.bitmap) {
            DeleteObject(oldest->second.bitmap);
        }
        pictures_.erase(oldest);
    }
}
