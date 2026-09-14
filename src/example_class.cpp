#include "example_class.h"


#include <clipper2/clipper.h>

using namespace godot;
using namespace Clipper2Lib;

void ClipShape::_bind_methods() {
    ClassDB::bind_method(
        D_METHOD("clear"),
        &ClipShape::clear
    );

    ClassDB::bind_method(
        D_METHOD("add_path", "points", "closed", "scale"),
        &ClipShape::add_path,
        DEFVAL(true),
        DEFVAL(1000.0)
    );

    ClassDB::bind_method(
        D_METHOD("add_paths", "paths", "closed", "scale"),
        &ClipShape::add_paths,
        DEFVAL(true),
        DEFVAL(1000.0)
    );

    ClassDB::bind_method(
        D_METHOD("to_packed_paths", "scale"),
        &ClipShape::to_packed_paths,
        DEFVAL(1000.0)
    );


    ClassDB::bind_method(
        D_METHOD("size"),
        &ClipShape::size
    );

    ClassDB::bind_method(
        D_METHOD("merge_contents"),
        &ClipShape::merge_contents
    );

    ClassDB::bind_method(
        D_METHOD("intersect", "other"),
        &ClipShape::intersect
    );


    ClassDB::bind_method(
        D_METHOD("merge", "other"),
        &ClipShape::intersect
    );


    ClassDB::bind_method(
        D_METHOD("clip", "other"),
        &ClipShape::clip
    );

    ClassDB::bind_method(
        D_METHOD("get_bounds", "scale"),
        &ClipShape::get_bounds,
        DEFVAL(1000.0)
    );

    ClassDB::bind_method(
        D_METHOD("get_area", "scale"),
        &ClipShape::get_area,
        DEFVAL(1000.0)
    );


}

void ClipShape::clear() {
    paths.clear();
}

int64_t ClipShape::add_path(
    const PackedVector2Array &points,
    bool closed,
    double scale
) {
    if (points.size() < 2) {
        return -1;
    }

    Path64 path;
    path.reserve(points.size());

    for (int i = 0; i < points.size(); i++) {
        const Vector2 p = points[i];

        path.emplace_back(
            static_cast<int64_t>(Math::round(p.x * scale)),
            static_cast<int64_t>(Math::round(p.y * scale))
        );
    }

    if (closed && path.size() > 2) {
        // Remove duplicate final point if supplied.
        if (path.front() == path.back()) {
            path.pop_back();
        }
    }

    paths.push_back(std::move(path));
    return paths.size() - 1;
}

void ClipShape::add_paths(
    const Array &input,
    bool closed,
    double scale
) {
    for (int i = 0; i < input.size(); i++) {
        Variant value = input[i];

        if (value.get_type() != Variant::PACKED_VECTOR2_ARRAY) {
            continue;
        }

        add_path(
            value,
            closed,
            scale
        );
    }
}

Array ClipShape::to_packed_paths(double scale) const {
    Array result;

    for (const Path64 &path : paths) {
        PackedVector2Array godot_path;
        godot_path.resize(path.size());

        for (int i = 0; i < path.size(); i++) {
            godot_path[i] = Vector2(
                static_cast<float>(path[i].x / scale),
                static_cast<float>(path[i].y / scale)
            );
        }

        result.push_back(godot_path);
    }

    return result;
}

int64_t ClipShape::size() const {
    return paths.size();
}


const Paths64 &ClipShape::get_native() const {
    return paths;
}





Ref<ClipShape> ClipShape::merge_contents() const {
    Ref<ClipShape> result;
    result.instantiate();

    result->paths = Clipper2Lib::Union(
        paths,
        FillRule::NonZero
    );

	result->paths = Clipper2Lib::SimplifyPaths(result->paths, .1, false);

    return result;
}

/*

Ref<ClipShape> ClipShape::merge(
    const Ref<ClipShape> &other
) const {
    Ref<ClipShape> result;
    result.instantiate();

    if (other.is_null()) {
        return result;
    }

	result.add_paths(other.to_packed_paths());
	result.add_paths(to_packed_paths());

    result->paths = Clipper2Lib::Union(
        result,
        FillRule::NonZero
    );


	result->paths = Clipper2Lib::SimplifyPaths(result->paths, .1, false);

    return result;
}
*/

Ref<ClipShape> ClipShape::intersect(
    const Ref<ClipShape> &other
) const {
    Ref<ClipShape> result;
    result.instantiate();

    if (other.is_null()) {
        return result;
    }

    result->paths = Clipper2Lib::Intersect(
        paths,
        other->paths,
        FillRule::NonZero
    );


	result->paths = Clipper2Lib::SimplifyPaths(result->paths, .1, false);

    return result;
}

Ref<ClipShape> ClipShape::clip(
    const Ref<ClipShape> &other
) const {
    Ref<ClipShape> result;
    result.instantiate();

    if (other.is_null()) {
        return result;
    }

    result->paths = Clipper2Lib::Difference(
        paths,
        other->paths,
        FillRule::NonZero
    );


	result->paths = Clipper2Lib::SimplifyPaths(result->paths, .1, false);

    return result;
}



Rect2 ClipShape::get_bounds(double scale) const {
    if (paths.empty() || scale == 0.0) {
        return Rect2();
    }

    const Rect64 bounds = Clipper2Lib::GetBounds(paths);
    const double inverse_scale = 1.0 / scale;

    return Rect2(
        Vector2(
            static_cast<float>(bounds.left * inverse_scale),
            static_cast<float>(bounds.top * inverse_scale)
        ),
        Vector2(
            static_cast<float>((bounds.right - bounds.left) * inverse_scale),
            static_cast<float>((bounds.bottom - bounds.top) * inverse_scale)
        )
    );
}



double ClipShape::get_area(double scale) const {

	return Clipper2Lib::Area(paths) / (scale * scale);

	}