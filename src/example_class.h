#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>


#include <clipper2/clipper.h>

using namespace godot;
using namespace Clipper2Lib;


class ClipShape : public RefCounted {
	GDCLASS(ClipShape, RefCounted)

protected:
	static void _bind_methods();

private:
	Paths64 paths;


public:
    void clear();

    int64_t add_path(
        const godot::PackedVector2Array &points,
        bool closed = true,
        double scale = 1000.0
    );


	//Path64 get_path(int64_t index) const;

    void add_paths(
        const godot::Array &input,
        bool closed = true,
        double scale = 1000.0
    );

    Array to_packed_paths(double scale = 1000.0) const;

    int64_t size() const;

    const Paths64 &get_native() const;





    Ref<ClipShape> merge_contents() const;

	Ref<ClipShape> intersect( const Ref<ClipShape> &other ) const ;
	
	Ref<ClipShape> merge( const Ref<ClipShape> &other ) const ;

	Ref<ClipShape> clip( const Ref<ClipShape> &other ) const ;


    Rect2 get_bounds(double scale = 1000.0) const;

	double get_area(double scale = 1000.0) const;


};
