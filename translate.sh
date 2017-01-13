text="$1"
source_lang=${2:-"de"}
target_lang=${3:-"en"}

out_dir="/datadrive/nlp/output"
mosesdecoder_path="/datadrive/mosesdecoder"

translation_dir=$out_dir/translation
moses_ini_path=$out_dir/train/model/moses.ini
moses=$mosesdecoder_path/bin/moses

# scripts
clean_corpus_n=$mosesdecoder_path/scripts/training/clean-corpus-n.perl
tokenize=$mosesdecoder_path/scripts/tokenizer/tokenizer.perl
truecase=$mosesdecoder_path/scripts/recaser/truecase.perl
detruecase=$mosesdecoder_path/scripts/recaser/detruecase.perl
multi_bleu=$mosesdecoder_path/scripts/generic/multi-bleu.perl

mkdir $translation_dir

echo "Clean..."
$clean_corpus_n $text $source_lang $target_lang $translation_dir/text.clean 1 50

echo "Tokenize..."
$tokenize -l $source_lang -threads 16 \
          < $translation_dir/text.clean.$source_lang \
          > $translation_dir/text.clean.tok.$source_lang

$tokenize -l $target_lang -threads 16 \
          < $translation_dir/text.clean.$target_lang \
          > $translation_dir/text.clean.tok.$target_lang

echo "Truecase..."
$truecase --model $out_dir/truecase-model.$source_lang \
          < $translation_dir/text.clean.tok.$source_lang > $translation_dir/text.clean.tok.truecase.$source_lang

echo "Translate..."
cat $translation_dir/text.clean.tok.truecase.$source_lang  \
    | $moses -threads all -f $moses_ini_path > $translation_dir/text.clean.tok.truecase.translated.$target_lang

echo "Detruecase..."
$detruecase $out_dir/truecase-model.$target_lang \
            < $translation_dir/text.clean.tok.truecase.translated.$target_lang \
            > $translation_dir/text.clean.tok.detruecase.translated.$target_lang

echo "Calculate Bleu Score..."
$multi_bleu $translation_dir/text.clean.tok.$target_lang \
            < $translation_dir/text.clean.tok.detruecase.translated.$target_lang \
            > $translation_dir/bleu-score.log

cat $translation_dir/bleu-score.log

echo "Done."
