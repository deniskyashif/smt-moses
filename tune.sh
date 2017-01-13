text="$1"
source_lang=${2:-"de"}
target_lang=${3:-"en"}

out_dir="/datadrive/nlp/output"
mosesdecoder_path="/datadrive/mosesdecoder"

tuning_dir=$out_dir/tuning
moses_ini_path=$out_dir/train/model/moses.ini
moses=$mosesdecoder_path/bin/moses
mert_moses=$mosesdecoder_path/scripts/training/mert-moses.pl

# Scripts
clean_corpus_n=$mosesdecoder_path/scripts/training/clean-corpus-n.perl
tokenize=$mosesdecoder_path/scripts/tokenizer/tokenizer.perl
truecase=$mosesdecoder_path/scripts/recaser/truecase.perl

mkdir $tuning_dir

echo "Clean..."
$clean_corpus_n $text $source_lang $target_lang $tuning_dir/text.clean 1 50

echo "Tokenize..."
$tokenize -l $source_lang -threads 16 \
          < $tuning_dir/text.clean.${source_lang} \
          > $tuning_dir/text.clean.tok.${source_lang}

$tokenize -l $target_lang -threads 16 \
          < $tuning_dir/text.clean.${target_lang} \
          > $tuning_dir/text.clean.tok.${target_lang}

echo "Truecase..."
$truecase --model $out_dir/truecase-model.${source_lang} \
          < $tuning_dir/text.clean.tok.${source_lang} \
          > $tuning_dir/text.clean.tok.truecase.${source_lang}

$truecase --model $out_dir/truecase-model.${target_lang} \
          < $tuning_dir/text.clean.tok.${target_lang} \
          > $tuning_dir/text.clean.tok.truecase.${target_lang}

echo "Tuning..."
$mert_moses $tuning_dir/text.clean.tok.truecase.${source_lang} \
            $tuning_dir/text.clean.tok.truecase.${target_lang} \
            $moses $moses_ini_path --decoder-flags="-threads all" \
            --mertargs="--sctype BLEU --scconfig weights:0.6+0.4 --threads all" \
            --working-dir $tuning_dir/mert-work \
            > $tuning_dir/mert.output
