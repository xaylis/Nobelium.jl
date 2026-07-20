# https://docs.discord.com/developers/components/reference

export Component, UnknownComponent, ComponentType, ComponentTypes, ButtonStyle, ButtonStyles,
    TextInputStyle, TextInputStyles, SelectOption, SelectDefaultValue, UnfurledMediaItem,
    MediaGalleryItem, ActionRow, Button, StringSelect, UserSelect, RoleSelect,
    MentionableSelect, ChannelSelect, TextInput, Section, TextDisplayComponent, Thumbnail,
    MediaGallery, FileComponent, Separator, Container, Label, FileUpload, RadioGroup,
    CheckboxGroup, Checkbox

@discord_enum ComponentType UInt8 begin
    ACTION_ROW = 1
    BUTTON = 2
    STRING_SELECT = 3
    TEXT_INPUT = 4
    USER_SELECT = 5
    ROLE_SELECT = 6
    MENTIONABLE_SELECT = 7
    CHANNEL_SELECT = 8
    SECTION = 9
    TEXT_DISPLAY = 10
    THUMBNAIL = 11
    MEDIA_GALLERY = 12
    FILE = 13
    SEPARATOR = 14
    CONTAINER = 17
    LABEL = 18
    FILE_UPLOAD = 19
    RADIO_GROUP = 21
    CHECKBOX_GROUP = 22
    CHECKBOX = 23
end

@discord_enum ButtonStyle UInt8 begin
    PRIMARY = 1
    SECONDARY = 2
    SUCCESS = 3
    DANGER = 4
    LINK = 5
    PREMIUM = 6
end

@discord_enum TextInputStyle UInt8 begin
    SHORT = 1
    PARAGRAPH = 2
end

"""
    Component

Supertype of every message or modal component. Deserializes polymorphically
from the numeric `type` field; an unrecognized type yields an
[`UnknownComponent`](@ref) rather than throwing.
"""
abstract type Component <: DiscordObject end

@discord_object struct SelectOption
    label::String
    value::String
    description::Optional{String}
    emoji::Optional{Emoji}
    default::Optional{Bool}
end

@discord_object struct SelectDefaultValue
    id::Snowflake
    type::String
end

@discord_object struct UnfurledMediaItem
    url::Optional{String}
    attachment_id::Optional{Snowflake}
end

@discord_object struct MediaGalleryItem
    media::UnfurledMediaItem
    description::Optional{String}
    spoiler::Optional{Bool}
end

@discord_object struct ActionRow <: Component
    type::ComponentType
    id::Optional{Int}
    components::Vector{Component}
end

@discord_object struct Button <: Component
    type::ComponentType
    id::Optional{Int}
    style::ButtonStyle
    label::Optional{String}
    emoji::Optional{Emoji}
    custom_id::Optional{String}
    sku_id::Optional{Snowflake}
    url::Optional{String}
    disabled::Optional{Bool}
end

@discord_object struct StringSelect <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    options::Vector{SelectOption}
    placeholder::Optional{String}
    min_values::Optional{Int}
    max_values::Optional{Int}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct TextInput <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    style::TextInputStyle
    min_length::Optional{Int}
    max_length::Optional{Int}
    required::Optional{Bool}
    value::Optional{String}
    placeholder::Optional{String}
end

@discord_object struct UserSelect <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    placeholder::Optional{String}
    default_values::Optional{Vector{SelectDefaultValue}}
    min_values::Optional{Int}
    max_values::Optional{Int}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct RoleSelect <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    placeholder::Optional{String}
    default_values::Optional{Vector{SelectDefaultValue}}
    min_values::Optional{Int}
    max_values::Optional{Int}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct MentionableSelect <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    placeholder::Optional{String}
    default_values::Optional{Vector{SelectDefaultValue}}
    min_values::Optional{Int}
    max_values::Optional{Int}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct ChannelSelect <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    channel_types::Optional{Vector{ChannelType}}
    placeholder::Optional{String}
    default_values::Optional{Vector{SelectDefaultValue}}
    min_values::Optional{Int}
    max_values::Optional{Int}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct TextDisplayComponent <: Component
    type::ComponentType
    id::Optional{Int}
    content::String
end

@discord_object struct Thumbnail <: Component
    type::ComponentType
    id::Optional{Int}
    media::UnfurledMediaItem
    description::Optional{String}
    spoiler::Optional{Bool}
end

"""
    Section

A layout component (components-v2) grouping up to three `TextDisplayComponent`
components with a `Button` or `Thumbnail` accessory.
"""
@discord_object struct Section <: Component
    type::ComponentType
    id::Optional{Int}
    components::Vector{Component}
    accessory::Component
end

@discord_object struct MediaGallery <: Component
    type::ComponentType
    id::Optional{Int}
    items::Vector{MediaGalleryItem}
end

"""
    FileComponent

A components-v2 attachment reference; Discord calls this component "File" on
the wire (`FileComponent` avoids clashing with [`DiscordFile`](@ref)).
"""
@discord_object struct FileComponent <: Component
    type::ComponentType
    id::Optional{Int}
    attachment_id::Snowflake
end

@discord_object struct Separator <: Component
    type::ComponentType
    id::Optional{Int}
end

"""
    Container

A components-v2 layout component grouping other components behind an optional
accent color, similar to an embed's side bar.
"""
@discord_object struct Container <: Component
    type::ComponentType
    id::Optional{Int}
    components::Vector{Component}
    accent_color::OptionalNullable{Int}
    spoiler::Optional{Bool}
end

"""
    Label

A modal-only wrapper attaching a label and description to an interactive
child component.
"""
@discord_object struct Label <: Component
    type::ComponentType
    id::Optional{Int}
    label::String
    description::Optional{String}
    component::Component
end

@discord_object struct FileUpload <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct RadioGroup <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    options::Vector{SelectOption}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct CheckboxGroup <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    options::Vector{SelectOption}
    required::Optional{Bool}
    disabled::Optional{Bool}
end

@discord_object struct Checkbox <: Component
    type::ComponentType
    id::Optional{Int}
    custom_id::String
    required::Optional{Bool}
    disabled::Optional{Bool}
end

"""
    UnknownComponent

A component whose `type` this version of Nobelium doesn't recognize yet.
`raw` holds the untouched payload so callers can still inspect it.
"""
@discord_object struct UnknownComponent <: Component
    type::Int
    raw::Any
end

const _COMPONENT_TYPES = Dict{Int,Type}(
    ComponentTypes.ACTION_ROW.value => ActionRow,
    ComponentTypes.BUTTON.value => Button,
    ComponentTypes.STRING_SELECT.value => StringSelect,
    ComponentTypes.TEXT_INPUT.value => TextInput,
    ComponentTypes.USER_SELECT.value => UserSelect,
    ComponentTypes.ROLE_SELECT.value => RoleSelect,
    ComponentTypes.MENTIONABLE_SELECT.value => MentionableSelect,
    ComponentTypes.CHANNEL_SELECT.value => ChannelSelect,
    ComponentTypes.SECTION.value => Section,
    ComponentTypes.TEXT_DISPLAY.value => TextDisplayComponent,
    ComponentTypes.THUMBNAIL.value => Thumbnail,
    ComponentTypes.MEDIA_GALLERY.value => MediaGallery,
    ComponentTypes.FILE.value => FileComponent,
    ComponentTypes.SEPARATOR.value => Separator,
    ComponentTypes.CONTAINER.value => Container,
    ComponentTypes.LABEL.value => Label,
    ComponentTypes.FILE_UPLOAD.value => FileUpload,
    ComponentTypes.RADIO_GROUP.value => RadioGroup,
    ComponentTypes.CHECKBOX_GROUP.value => CheckboxGroup,
    ComponentTypes.CHECKBOX.value => Checkbox,
)

StructTypes.StructType(::Type{Component}) = StructTypes.CustomStruct()
StructTypes.lowertype(::Type{Component}) = Any

function _construct_component(obj)
    type = Int(get(obj, :type) do
        obj["type"]
    end)
    T = get(_COMPONENT_TYPES, type, nothing)
    T === nothing ? UnknownComponent(type, obj) : _construct(T, obj)
end

StructTypes.construct(::Type{Component}, obj::JSON3.Object; kw...) = _construct_component(obj)
StructTypes.construct(::Type{Component}, obj::AbstractDict; kw...) = _construct_component(obj)
