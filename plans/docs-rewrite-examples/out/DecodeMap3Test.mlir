module {
  "func.func"() ({
        %5 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 3, function = @DecodeMap3Test_lambda_0, num_captured = 0} : () -> !eco.value 
        %6 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_1}> : () -> !eco.value 
        %7 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_1}> : () -> !eco.value 
        %8 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_1}> : () -> !eco.value 
        %13 = "eco.project.custom"(%6) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %14 = "eco.project.custom"(%7) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %15 = "eco.project.custom"(%8) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %16 = "eco.papCreate"(%13, %14, %15, %5) {_fast_evaluator = @DecodeMap3Test_lambda_9$cap, _operand_types = [!eco.value, !eco.value, !eco.value, !eco.value], arity = 6, function = @DecodeMap3Test_lambda_9$clo, num_captured = 4, slot_kinds = array<i8: 0, 0, 0, 0>} : (!eco.value, !eco.value, !eco.value, !eco.value) -> !eco.value 
        %0 = "eco.construct.custom"(%16) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        %18 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %19 = "arith.constant"() {value = 300 : i64} : () -> i64 
        %20 = "eco.construct.custom"(%19) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %21 = "eco.construct.list"(%20, %18) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %22 = "arith.constant"() {value = 200 : i64} : () -> i64 
        %23 = "eco.construct.custom"(%22) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %24 = "eco.construct.list"(%23, %21) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %25 = "arith.constant"() {value = 100 : i64} : () -> i64 
        %26 = "eco.construct.custom"(%25) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %27 = "eco.construct.list"(%26, %24) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %28 = "arith.constant"() {value = 3 : i32} : () -> i32 
        %1 = "bf.alloc"(%28) {_operand_types = [i32]} : (i32) -> !eco.value 
        %30 = "bf.cursor.init"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> !bf.cursor 
        %31 = "arith.constant"() {value = 100 : i64} : () -> i64 
        %32 = "bf.write.u8"(%30, %31) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %33 = "arith.constant"() {value = 200 : i64} : () -> i64 
        %34 = "bf.write.u8"(%32, %33) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %35 = "arith.constant"() {value = 300 : i64} : () -> i64 
        %36 = "bf.write.u8"(%34, %35) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %39 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %37 = "eco.int.negate"(%39) {_operand_types = [i64]} : (i64) -> i64 
        %41 = "eco.project.custom"(%0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %38 = "eco.call"(%41, %1) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        %43 = "eco.get_tag"(%38) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %44 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %45 = "arith.cmpi"(%43, %44) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %2 = "eco.case"(%45) ({
              %47 = "eco.project.custom"(%38) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%47) {_operand_types = [i64]} : (i64) -> () 
        }, {
              "eco.yield"(%37) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        %49 = "eco.string_literal"() {value = "DecodeMap3Test"} : () -> !eco.value 
        %3 = "eco.box"(%2) {_operand_types = [i64]} : (i64) -> !eco.value 
        "eco.dbg"(%49, %3) {_operand_types = [!eco.value, !eco.value], arg_type_ids = array<i64: 1, 4>} : (!eco.value, !eco.value) -> () 
        %4 = "eco.string.from_int"(%2) {_operand_types = [i64]} : (i64) -> !eco.value 
        %52 = "eco.call"(%4) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%52) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "DecodeMap3Test_main_$_0", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Bytes_Decode_unsignedInt8_$_1"} : () -> () 
  "func.func"() ({
        %0 = "eco.papCreate"() {arity = 2, function = @Elm_Kernel_Bytes_read_u8, num_captured = 0} : () -> !eco.value 
        %1 = "eco.construct.custom"(%0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Bytes_Decode_unsignedInt8_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Bytes_Encode_U8_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_5", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: !eco.value, %bs: !eco.value):
        %2 = "eco.project.custom"(%_v0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%2, %bs) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["custom:0:1:v", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Bytes_Decode_decode_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%width: i64, %builders: !eco.value):
        %2 = "arith.constant"() {value = false} : () -> i1 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4, %5, %6, %7 = "scf.while"(%width, %builders, %2, %3) ({
            ^bb0(%8: i64, %9: !eco.value, %10: i1, %11: i64):
              %13 = "arith.constant"() {value = true} : () -> i1 
              %12 = "arith.xori"(%10, %13) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%12, %8, %9, %10, %11) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%14: i64, %15: !eco.value, %16: i1, %17: i64):
              %18 = "eco.get_tag"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %19 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %28, %29, %30, %31 = "eco.case"(%20) ({
                    %21 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%14, %15, %21, %14) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %22 = "eco.project.list_head"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %23 = "eco.project.list_tail"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %24 = "eco.call"(%22) <{_operand_types = [!eco.value], callee = @Bytes_Encode_getWidth_$_12}> : (!eco.value) -> i64 
                    %25 = "eco.int.add"(%14, %24) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %26 = "arith.constant"() {value = false} : () -> i1 
                    %27 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%25, %23, %26, %27) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%28, %29, %30, %31) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%7) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "Bytes_Encode_getWidths_$_10", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Bytes_Encode_Seq_$_11", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%builder: !eco.value):
        %15 = "eco.case"(%builder) ({
              %1 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%1) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %2 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%2) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %3 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%3) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%4) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %5 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%5) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %6 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%6) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %7 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%7) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %8 = "arith.constant"() {value = 8 : i64} : () -> i64 
              "eco.yield"(%8) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %10 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%10) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %12 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%12) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %13 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %14 = "eco.call"(%13) <{_operand_types = [!eco.value], callee = @Elm_Kernel_Bytes_width, eco.cse_safe}> : (!eco.value) -> i64 
              "eco.yield"(%14) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>} : (!eco.value) -> i64 
        "eco.return"(%15) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "Bytes_Encode_getWidth_$_12", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_13", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_14", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_15: !eco.value, %mono_inline_14: !eco.value, %mono_inline_13: !eco.value, %mono_inline_0: !eco.value, %bites: !eco.value, %offset: i64):
        %9 = "eco.papExtend"(%mono_inline_15, %bites, %offset) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %12 = "eco.project.tuple2"(%9) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %14 = "eco.project.tuple2"(%9) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %15 = "eco.papExtend"(%mono_inline_14, %bites, %12) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %18 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %20 = "eco.project.tuple2"(%15) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %21 = "eco.papExtend"(%mono_inline_13, %bites, %18) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %24 = "eco.project.tuple2"(%21) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %26 = "eco.project.tuple2"(%21) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %27 = "eco.papExtend"(%mono_inline_0, %14, %20, %26) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @DecodeMap3Test_lambda_0, _operand_types = [!eco.value, i64, i64, i64], remaining_arity = 3, slot_kinds = array<i8: 1, 1, 1>} : (!eco.value, i64, i64, i64) -> i64 
        %28 = "eco.construct.tuple2"(%24, %27) {_operand_types = [i64, i64], unboxed_bitmap = 5} : (i64, i64) -> !eco.value 
        "eco.return"(%28) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "value", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "DecodeMap3Test_lambda_9$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %bites: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.project.closure"(%closure) {index = 1, is_unboxed = false} : (!eco.value) -> !eco.value 
        %5 = "eco.project.closure"(%closure) {index = 2, is_unboxed = false} : (!eco.value) -> !eco.value 
        %6 = "eco.project.closure"(%closure) {index = 3, is_unboxed = false} : (!eco.value) -> !eco.value 
        %7 = "eco.call"(%3, %4, %5, %6, %bites, %offset) <{_operand_types = [!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64], callee = @DecodeMap3Test_lambda_9$cap}> : (!eco.value, !eco.value, !eco.value, !eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:i"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "DecodeMap3Test_lambda_9$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%a: i64, %b: i64, %c: i64):
        %9 = "eco.int.add"(%a, %b) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %10 = "eco.int.add"(%9, %c) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%10) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64, i64) -> (i64), sym_name = "DecodeMap3Test_lambda_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @DecodeMap3Test_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_decode", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_u8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "arith.constant"() {value = 0 : i64} : () -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.gc_leaf, eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), is_kernel = true, sym_name = "Elm_Kernel_Bytes_width", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 0, 0, 0], [0, 1, 0, 1], [1, 3, 1, 2], [2, 5, 3, 2], [3, 6, 5, 1], [4, 7, 6, 2], [5, 8, 8, 2], [6, 9, 10, 2], [7, 10, 12, 2], [8, 11, 14, 2], [9, 12, 16, 2], [10, 0, 18, 1], [0, 13, 21, 1]], fields = [[2, 4], [2, 3], [4, 4], [2, 3], [4, 4], [2, 4], [2, 3], [4, 4], [2, 3], [4, 4], [2, 3], [4, 2], [2, 3], [4, 2], [2, 4], [4, 6], [2, 4], [4, 1], [2, 0], [0, 4], [0, 4], [2, 9]], func_args = [4, 0], strings = ["Bytes", "I8", "field0", "I16", "field1", "I32", "U8", "U16", "U32", "F32", "F64", "Seq", "Utf8", "Decoder"], types = [[0, 4, 0, 1], [1, 0, 4], [2, 0, 1], [3, 4, 1, 0], [4, 0, 0], [5, 4, 1, 11], [6, 1, 5], [7, 2, 2, 19, 2], [8, 5, 0, 1, 7], [9, 5, 1, 1, 8], [10, 4, 12, 1]]} : () -> () 
} 
