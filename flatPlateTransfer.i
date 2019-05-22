Simulations:
  - name: sim1
    time_integrator: ti_1
    optimizer: opt1

linear_solvers:

  - name: solve_scalar
    type: tpetra
    method: gmres
    preconditioner: sgs
    tolerance: 1e-5
    max_iterations: 50
    kspace: 50
    output_level: 0

  - name: solve_cont
    type: tpetra
    method: gmres
    preconditioner: muelu
    tolerance: 1e-5
    max_iterations: 50
    kspace: 50
    output_level: 0

#  - name: solve_cont
#    type: hypre
#    method: hypre_gmres
#    preconditioner: boomerAMG
#    tolerance: 1e-5
#    max_iterations: 200
#    kspace: 5
#    output_level: 0

transfers:

  - name: xfer_io_fluids
    type: geometric
    realm_pair: [realm_1, ioRealm]
    from_target_name: outlet
    to_target_name: outlet
    objective: input_output
    search_tolerance: 5.0e-4
    transfer_variables:
      - [velocity, velocity]
      - [pressure, pressure]
      - [turbulent_ke, turbulent_ke]
      - [specific_dissipation_rate, specific_dissipation_rate]
      - [minimum_distance_to_wall, minimum_distance_to_wall]

realms:

  - name: realm_1
    mesh: restart/flatPlateInflowCoarse.rst
    use_edges: no 
    check_for_missing_bcs: yes
    automatic_decomposition_type: rcb

    time_step_control:
     target_courant: 10.0
     time_step_change_factor: 1.2

    equation_systems:
      name: theEqSys
      max_iterations: 2 

      solver_system_specification:
        velocity: solve_scalar
        turbulent_ke: solve_scalar
        specific_dissipation_rate: solve_scalar
        pressure: solve_cont

      systems:

        - LowMachEOM:
            name: myLowMach
            max_iterations: 1
            convergence_tolerance: 1e-5

        - ShearStressTransport:
            name: mySST 
            max_iterations: 3
            convergence_tolerance: 1e-5

    initial_conditions:
      - constant: ic_1
        target_name: Unspecified-2-HEX
        value:
          pressure: 0
          velocity: [34.6,0.0,0.0]
          turbulent_ke: 0.00108
          specific_dissipation_rate: 7710.9

    material_properties:
      target_name: Unspecified-2-HEX
      specifications:
        - name: density
          type: constant
          value: 1.185
        - name: viscosity
          type: constant
          value: 1.8398e-5

    boundary_conditions:

    - wall_boundary_condition: bc_wall
      target_name: bottomwall
      wall_user_data:
        velocity: [0,0,0]
        turbulent_ke: 0.0
        use_wall_function: no

    - inflow_boundary_condition: bc_inflow
      target_name: inlet
      inflow_user_data:
        velocity: [34.6,0.0,0.0]
        turbulent_ke: 0.00108
        specific_dissipation_rate: 7710.9

    - open_boundary_condition: bc_open
      target_name: outlet
      open_user_data:
        velocity: [0,0,0]
        pressure: 0.0
        turbulent_ke: 0.00108
        specific_dissipation_rate: 7710.9

    - open_boundary_condition: bc_open
      target_name: top
      open_user_data:
        velocity: [34.6,0,0]
        pressure: 0.0
        turbulent_ke: 0.00108
        specific_dissipation_rate: 7710.9

    - periodic_boundary_condition: bc_front_back
      target_name: [front, back]
      periodic_user_data:
        search_tolerance: 0.0001

    solution_options:
      name: myOptions
      turbulence_model: sst_des

      options:
        - hybrid_factor:
            velocity: 0.0 
            turbulent_ke: 1.0
            specific_dissipation_rate: 1.0

        - alpha:
            velocity: 0.0 

        - limiter:
            pressure: no
            velocity: no
            turbulent_ke: no
            specific_dissipation_rate: yes

        - projected_nodal_gradient:
            velocity: element
            pressure: element 
            turbulent_ke: element
            specific_dissipation_rate: element
   
        - input_variables_from_file:
            minimum_distance_to_wall: minimum_distance_to_wall
 
        - turbulence_model_constants:
            SDRWallFactor: 0.625

    output:
      output_data_base_name: results/flatPlateInflowCoarse-rst.e
      output_frequency: 500
      output_node_set: no 
      output_variables:
       - velocity
       - pressure
       - pressure_force
       - tau_wall
       - turbulent_ke
       - specific_dissipation_rate
       - minimum_distance_to_wall
       - sst_f_one_blending
       - turbulent_viscosity

    restart:
      restart_data_base_name: restart/flatPlateInflowCoarse-rst.rst
      output_frequency: 2500
      restart_time: 1.00
 
  - name: ioRealm
    mesh: flatPlateInflowCoarse-bdry.exo 
    type: input_output

    field_registration:
      specifications:
        - field_name: velocity
          target_name: outlet
          field_size: 3
          field_type: node_rank

        - field_name: pressure
          target_name: outlet
          field_size: 1
          field_type: node_rank

        - field_name: turbulent_ke
          target_name: outlet
          field_size: 1
          field_type: node_rank

        - field_name: specific_dissipation_rate
          target_name: outlet
          field_size: 1
          field_type: node_rank

        - field_name: minimum_distance_to_wall
          target_name: outlet
          field_size: 1
          field_type: node_rank

    output:
      output_data_base_name: IO_subset.e
      output_frequency: 1 
      output_node_set: no
      output_variables:
       - velocity
       - pressure
       - turbulent_ke
       - specific_dissipation_rate
       - minimum_distance_to_wall

Time_Integrators:
  - StandardTimeIntegrator:
      name: ti_1
      start_time: 0
      time_step: 1.0e-6
      termination_step_count: 1 
      time_stepping_type: adaptive
      time_step_count: 0
      second_order_accuracy: yes

      realms: 
        - realm_1
        - ioRealm
