require File.dirname(__FILE__) + "/common"

TREE_GENERATION_DATA = {
  :level_range => 1..4,
  :children_range => 1..6,
  :thread_range => 1..6,
  :drain_iterations => 0,
}

class TestGrind < Test::Unit::TestCase
  include TestCommon

  def test_grind
    run_generated_tree(TREE_GENERATION_DATA)
  end

  def generate_comp_tree(num_levels, num_children, drain_iterations)
    CompTree.build { |driver|
      root = :aaa
      last_name = root
      pick_names = lambda { |*args|
        (0..rand(num_children)).map {
          last_name = last_name.to_s.succ.to_sym
        }
      }
      drain = lambda { |*args|
        drain_iterations.times {
        }
      }
      build_tree = lambda { |parent, children, level|
        #trace "building #{parent} --> #{children.join(' ')}"
        
        driver.define(parent, *children, &drain)

        if level < num_levels
          children.each { |child|
            build_tree.call(child, pick_names.call, level + 1)
          }
        else
          children.each { |child|
            driver.define(child, &drain)
          }
        end
      }
      build_tree.call(root, pick_names.call, drain_iterations)
      driver
    }
  end

  def run_generated_tree(args)
    args[:level_range].each { |num_levels|
      args[:children_range].each { |num_children|
        separator
        bench_output {%{num_levels}}
        bench_output {%{num_children}}
        driver = generate_comp_tree(
          num_levels,
          num_children,
          args[:drain_iterations])
        args[:thread_range].each { |threads|
         bench_output {%{threads}}
          2.times {
            driver.reset(:aaa)
            result = nil
            bench = Benchmark.measure {
              result = driver.compute(:aaa, threads)
            }
            bench_output bench
            assert_equal(result, args[:drain_iterations])
          }
        }
      }
    }
  end
end