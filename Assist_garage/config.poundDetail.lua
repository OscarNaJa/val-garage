Config = Config or {}
-- vehicletype = 'car' , 'bike' , 'helicopter'
-- job = true  ถ้าใส่ จะให้เฉพาะคนที่มี job เท่านั้นถึงจะใช้ได้
Config.PoundMarker 	= { type = 36, r = 255, g = 165, b = 0, a=100, x = 1.5, y = 1.5, z = 1.2 }

Config.poundDetail = {

    {   
        location = vector3(1738.8896, 3716.7067, 34.078804),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(1738.3743, 3718.205, 34.05677),         ------------------------------ จุด Spawn รถ
        spawnheading = 21.86,                                            ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 202.67                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },
    
    {   
        location = vector3(398.07821, -1646.902, 29.291988),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(399.11328, -1645.715, 29.291988),         ------------------------------ จุด Spawn รถ
        spawnheading = 318.7749,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 136.6372                                                                      ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },

    {   
        location = vector3(1189.7933, -1536.562, 34.692428),              ------------------------------ จุดกดพาวน์รถ -- HOSPITAL
        spawnlocation = vector3(1185.5059, -1540.413, 34.69242),         ------------------------------ จุด Spawn รถ
        spawnheading = 88.94,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 180.39                                                                          ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },
   
    {   
        location = vector3(1853.6007, 2564.0114, 45.67208),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(1855.8339, 2563.9523, 45.67208),         ------------------------------ จุด Spawn รถ
        spawnheading = 271.53,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 89.59                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },
   
    {   
        location = vector3(-394.8435, 1118.7083, 327.44),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(-394.3539, 1120.5108, 327.44),         ------------------------------ จุด Spawn รถ
        spawnheading = 344.61,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 166.18                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
        }
    },
       
    {   --police
        location = vector3(457.7023, -1009.176, 28.301591),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(445.35577, -1021.38, 28.49551),         ------------------------------ จุด Spawn รถ
        spawnheading = 93.63,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 357.68                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },

    {   --police sand
        location = vector3(1895.2089, 3706.4716, 32.816764),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(1893.1781, 3705.2819, 32.8652),         ------------------------------ จุด Spawn รถ
        spawnheading = 120.39,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 300.72                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },
           
    -- {   --ambulance
    --     location = vector3(1157.909, -1595.357, 34.797897),              ------------------------------ จุดกดพาวน์รถ
    --     spawnlocation = vector3(1157.8762, -1598.463, 34.692668),         ------------------------------ จุด Spawn รถ
    --     spawnheading = 181.49,                                                                        ------------------------------ ทิศทางหน้ารถ
    --     vehicletype = 'car',
    Radius = 2.0,--     
    job = { 'police', 'ambulance', 'council' },
    --     Propspawn = {
    --         model   = "un_bendix_prop_pounds_assist",
    --         heading = 2.45                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
    
    --     }
    -- },

    {   --council
        location = vector3(-456.1337, 1136.0937, 327.44),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(-455.5841, 1138.1914, 327.44),         ------------------------------ จุด Spawn รถ
        spawnheading = 344.84,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'car',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 164.31                                                                        ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },

    --------- helicopter pound ---------
    { -- police city
        location = vector3(457.50646, -975.2376, 43.69181),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(449.21456, -981.2398, 43.691707),         ------------------------------ จุด Spawn รถ
        spawnheading = 87.72,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'helicopter',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 276.63                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },

    { -- medic city
        location = vector3(1152.1356, -1542.462, 48.144775),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(1141.9699, -1562.791, 48.14479),         ------------------------------ จุด Spawn รถ
        spawnheading = 1.5,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'helicopter',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 272.76                                                                           ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },

    { -- council city
        location = vector3(-434.6143, 1055.7476, 350.51553),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(-424.4115, 1067.379, 350.50772),         ------------------------------ จุด Spawn รถ
        spawnheading = 348.18789,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'helicopter',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 72.79                                                                         ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },

    { -- government sand
        location = vector3(1868.5708, 3647.9042, 33.920482),              ------------------------------ จุดกดพาวน์รถ
        spawnlocation = vector3(1856.461, 3640.5576, 35.96315),         ------------------------------ จุด Spawn รถ
        spawnheading = 32.6,                                                                        ------------------------------ ทิศทางหน้ารถ
        vehicletype = 'helicopter',
        Radius = 2.0,
        job = { 'police', 'ambulance', 'council' },
        Propspawn = {
            model   = "un_bendix_prop_pounds_assist",
            heading = 296.02386                                                                        ------------------------------ ทิศทาง Prop พาวน์รถ
    
        }
    },
}
