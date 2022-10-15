module quickd.graphics.level2d;
import quickd.graphics.renderapi;
public import quickd.graphics.level,
gfm.math.vector,
gfm.math.matrix;

/// Class of Level for 2D rendering.
class Level2D: Level{
    /// Render top level loop.
    void render(RenderAPI rapi){
        Actor2D[] tmp;
        synchronized(this) tmp = this.childListActors.dup;
        foreach(actor; tmp){
            actor.render(rapi);
        }
    }

    /// Add actor to "Root" of scene
    void addActor2D(string name, Actor2D actor, ulong position = -1){
        synchronized(this){
            /// Check errors for debug(disable in release for perfomance).
            debug {
                import quickd.core.logger;
                auto tmp = name in this.childMapActors;
                if(tmp !is null){
                    LogMessage message = LogMessage();

                    message.message     = "Can't adding new actor to level";
                    message.fullpath    = "Root." ~ name;
                    message.reason      =
                    "An actor \"" ~
                    "Root" ~ name ~
                    "\" already exists at this level of the level tree";
                    message.status      = LogMessage.Status.error;

                    globalLogger.log(message);

                    throw new Exception(message.message ~ ":\n" ~ message.reason);
                }
                /// Debug success log.
                LogMessage message = LogMessage();

                message.message     = "Adding new actor to level";
                message.fullpath    = "Root." ~ name;
                message.status      = LogMessage.Status.debugging;

                globalLogger.log(message);
            }
            /// Adding in actors map
            this.childMapActors[name] = actor;
            /// Adding in position array.
            if(position == -1){
                this.childListActors ~= actor;
            }else if(position == this.childListActors.length){
                this.childListActors ~= actor;
            }else{
                this.childListActors = this.childListActors[0..position] ~ actor ~ this.childListActors[position..$];
            }
            /// Set actor name and calculate matrix.
            actor.name = name;
            actor.recalculate();
        }
    }
    /// Remove actor from "Root" of scene
    void removeActor2D(string name){
        synchronized(this){
            /// Check errors for debug(disable in release for perfomance).
            debug{
                auto tmp = name in this.childMapActors;
                if(tmp is null){
                    import quickd.core.logger;
                    LogMessage message = LogMessage();

                    message.message     = "Can't remove actor from level";
                    message.fullpath    = "Root." ~ name;
                    message.reason      =
                    "An actor \"" ~
                    "Root." ~ name ~
                    "\" does not exist.";
                    message.status      = LogMessage.Status.error;

                    globalLogger.log(message);

                    throw new Exception(message.message ~ ":\n" ~ message.reason);
                }
                /// Debug success log.
                import quickd.core.logger;
                LogMessage message = LogMessage();

                message.message     = "Adding new actor to level";
                message.fullpath    = "Root." ~ name;
                message.status      = LogMessage.Status.debugging;

                globalLogger.log(message);
            }

            /// Check actor in map.
            Actor2D actor = this.childMapActors[name];
            /// Remove from actor list.
            if(actor !is null){
                foreach(i, ref el; this.childListActors)
                    if((actor) is el){
                        this.childListActors = this.childListActors[0 .. i] ~ this.childListActors[i+1 .. $];
                        break;
                    }
                actor.name = "NULL";
            }
            /// Remove from map list.
            this.childMapActors.remove(name);
        }
    }
    void setPosition(string name, ulong position){
        /// TODO: Make implement;
    }

private:
    Actor2D[string] childMapActors;
    Actor2D[]       childListActors;
}

/// Class of Actor for 2D rendering.
class Actor2D: Actor{
    void setRenderable(){
        /// TODO: Make implement;
    }
    /// Render top level loop.
    void render(RenderAPI rapi){
        if(this.enable){
            Actor2D[] tmp;
            synchronized(this) tmp = this.childListActors.dup;
            foreach(actor; tmp){
                actor.render(rapi);
            }
        }
    }

    /// Enable actor for rendering.
    void setEnable(bool state){
        this.enable = state;
    }

    /// Add actor to "Root" of scene
    void addActor2D(string name, Actor2D actor, ulong position = -1){
        synchronized(this){
            debug {
                import quickd.core.logger;
                auto tmp = name in this.childMapActors;
                if(tmp !is null){
                    LogMessage message = LogMessage();

                    message.message     = "Can't adding new actor to level";
                    message.fullpath    = this.getFullPath() ~ '.' ~ name;
                    message.reason      =
                    "An actor \"" ~
                    this.getFullPath() ~ '.' ~ name ~
                    "\" already exists at this level of the level tree";
                    message.status      = LogMessage.Status.error;

                    globalLogger.log(message);

                    throw new Exception(message.message ~ ":\n" ~ message.reason);
                }
                LogMessage message = LogMessage();

                message.message     = "Adding new actor to level";
                message.fullpath    = this.getFullPath() ~ '.' ~ name;
                message.status      = LogMessage.Status.debugging;

                globalLogger.log(message);
            }

            this.childMapActors[name] = actor;
            if(position == -1){
                this.childListActors ~= actor;
            }else if(position == this.childListActors.length){
                this.childListActors ~= actor;
            }else{
                this.childListActors = this.childListActors[0..position] ~ actor ~ this.childListActors[position..$];
            }

            actor.parrent = this;
            actor.name = name;
            actor.recalculate();
        }
    }
    /// Get actor full Path.
    string getFullPath(){
        if(this.parrent !is null){
            return parrent.getFullPath() ~ '.' ~ this.name;
        }
        return "Root." ~ this.name;
    }
    /// Remove actor from "Root" of scene
    void removeActor2D(string name){
        synchronized(this){
            debug{
                auto tmp = name in this.childMapActors;
                if (tmp is null){
                    import quickd.core.logger;
                    LogMessage message = LogMessage();

                    message.message     = "Can't remove actor from level";
                    message.fullpath    = this.getFullPath() ~ '.' ~ name;
                    message.reason      =
                    "An actor \"" ~
                    this.getFullPath() ~ '.' ~ name ~
                    "\" does not exist at this level of the level tree";
                    message.status      = LogMessage.Status.error;

                    globalLogger.log(message);

                    throw new Exception(message.message ~ ":\n" ~ message.reason);
                }
                import quickd.core.logger;
                LogMessage message = LogMessage();

                message.message     = "Adding new actor to level";
                message.fullpath    = this.getFullPath() ~ '.' ~ name;
                message.status      = LogMessage.Status.debugging;

                globalLogger.log(message);
            }

            /// Check actor in map.
            Actor2D actor = this.childMapActors[name];
            /// Remove from actor list.
            if (actor !is null){
                foreach (i, ref el; this.childListActors)
                    if ((actor) is el){
                        this.childListActors = this.childListActors[0 .. i] ~ this.childListActors[i+1 .. $];
                        break ;
                    }
                actor.name = "NULL";
                actor.parrent = null;
            }
            /// Remove from map list.
            this.childMapActors.remove(name);
        }
    }
    vec2!float globalPosition() const @safe @property pure nothrow{
        return this.globPosition;
    }
    vec2!float globalScale() const @safe @property pure nothrow{
        return this.globScale;
    }
    float globalRotation() const @safe @property pure nothrow{
        import std.math;
        return this.globRotation * 180f / PI;
    }
    void recalculate() @safe{
        import std.math;
        Actor2D[] tmp;

        synchronized(this){
            mat3!double locMatrix = calculateMatrix();

            this.globPosition.x = locMatrix.c[2][0];
            this.globPosition.y = locMatrix.c[2][1];
            this.globScale.x    = sqrt(locMatrix.c[0][0] * locMatrix.c[0][0] + locMatrix.c[0][1]*locMatrix.c[0][1]);
            this.globScale.y    = sqrt(locMatrix.c[1][0] * locMatrix.c[1][0] + locMatrix.c[1][1]*locMatrix.c[1][1]);
            this.globRotation = atan2(this.globScale.x*-locMatrix.c[0][1], this.globScale.y*locMatrix.c[1][1]);
            // atan2(sin(angle), cos(angle)) ~= angle
            this.globMatrix     = locMatrix;

            tmp = this.childListActors.dup;
        }
        import std.stdio;

        foreach(actor; tmp){
            actor.recalculate();
        }
    }

    vec2!float position() const @safe @property pure nothrow{
        return this.locPosition;
    }
    void position(vec2!float position) @safe @property{
        this.locPosition = position;
        import std.math;

        mat3!double locMatrix = calculateMatrix();

        this.globMatrix = locMatrix;
        this.globPosition = locMatrix.c[2][0..2];

        Actor2D[] tmp;
        synchronized(this) tmp = this.childListActors.dup;

        foreach(actor; tmp){
            actor.recalculate();
        }
    }

    vec2!float scale() const @safe @property pure nothrow{
        return this.locScale;
    }
    void scale(vec2!float scale) @safe @property{
        this.locScale = scale;
        import std.math;

        mat3!double locMatrix = calculateMatrix();

        this.globMatrix = locMatrix;
        this.globScale.x = sqrt(locMatrix.c[0][0] * locMatrix.c[0][0] + locMatrix.c[0][1]*locMatrix.c[0][1]);
        this.globScale.y = sqrt(locMatrix.c[1][0] * locMatrix.c[1][0] + locMatrix.c[1][1]*locMatrix.c[1][1]);

        Actor2D[] tmp;
        synchronized(this) tmp = this.childListActors.dup;

        foreach(actor; tmp){
            actor.recalculate();
        }
    }

    float rotation() const @safe @property pure nothrow{
        import std.math;
        return this.locRotation * 180f / PI;
    }
    void rotation(float rotation) @safe @property{
        import std.math;
        if(rotation > 360) {
            int count = cast(int)floor(rotation / 360.0);
            rotation += 360*count;
        }
        else if(rotation < -360) {
            int count = -cast(int)ceil(rotation / 360.0);
            rotation += 360*count;
        }

        this.locRotation = rotation / 180f * PI;

        mat3!double locMatrix = calculateMatrix();

        this.globMatrix = locMatrix;
        this.globScale.x = sqrt(locMatrix.c[0][0] * locMatrix.c[0][0] + locMatrix.c[0][1]*locMatrix.c[0][1]);
        this.globScale.y = sqrt(locMatrix.c[1][0] * locMatrix.c[1][0] + locMatrix.c[1][1]*locMatrix.c[1][1]);
        this.globRotation = atan2(this.globScale.x*-locMatrix.c[0][1], this.globScale.y*locMatrix.c[1][1]);

        Actor2D[] tmp;
        synchronized(this) tmp = this.childListActors.dup;

        foreach(actor; tmp){
            actor.recalculate();
        }
    }

private:
    mat3!double calculateMatrix() @safe{
        import std.math;
        mat3!double locMatrix = [
                    [cos(this.locRotation),   -sin(this.locRotation), 0f],
                    [sin(this.locRotation),  cos(this.locRotation),   0f],
                    [0f,                              0.0,            1f]
        ];
        if(this.parrent is null){
            locMatrix = mat3!float([
                    [this.locScale.x,          0f,           0f],
                    [          0,         this.locScale.y,   0f],
                    [this.locPosition.x,this.locPosition.y,  1f]
            ]) * locMatrix;
        }else {
            locMatrix = (locMatrix * mat3!float([
                    [this.locScale.x,          0f,           0f],
                    [          0,         this.locScale.y,   0f],
                    [this.locPosition.x,this.locPosition.y,  1f]
            ]))*parrent.globMatrix;
        }
        return locMatrix;
    }


    Actor2D         parrent;
    string          name = "NULL";

    Actor2D[string] childMapActors;
    Actor2D[]       childListActors;

    vec2!float  locPosition = [0, 0];
    vec2!float  locScale = [1,1];
    double      locRotation = 0;

    vec2!float  globPosition;
    vec2!float  globScale;
    double      globRotation;

    mat3!double  globMatrix;

    bool        enable = true;
}
unittest{
    import quickd;
    import std.math;
    import std.conv;

    scope(success){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ Actor.stringof ~ " — [");
        cwrite("✓".color(fg.green));
        write("]\n");
        stdout.flush();
    }
    scope(failure){
        import std.stdio;
        import colorize : fg, color, cwrite;
        write(__MODULE__ ~ "." ~ Actor.stringof ~ " — [");
        cwrite("✖".color(fg.red));
        write("]\n");
        stdout.flush();
    }

    Level2D level = new Level2D;
    Actor2D actor1 = new Actor2D;
    Actor2D actor2 = new Actor2D;
    Actor2D actor3 = new Actor2D;
    Actor2D actor4 = new Actor2D;
    Actor2D actor5 = new Actor2D;

    level.addActor2D("actor1", actor1);
    actor1.addActor2D("actor54", actor2);
    actor1.addActor2D("actor45", actor3);
    actor3.addActor2D("actor23", actor4);
    actor4.addActor2D("actor23", actor5);

    actor1.position = vec2!float([5f, 0]);
    actor1.rotation = 90.0;
    auto position = actor4.globalPosition();
    auto rotation = actor4.globalRotation();
    if(!position.x.isClose(3.06152e-16) || !position.y.isClose(-5)){
        throw new Exception("Position calculation is't curretly work: " ~ position.to!string ~ " != [3.06152e-16, -5]");
    }
    if(!rotation.isClose(90)){
        throw new Exception("Rotation calculation is't curretly work: " ~ rotation.to!string ~ " != 90");
    }
}